local QBCore = nil
local ESX = nil

if Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

function sendNotification(source, message, notifType)
    if Config.Notify == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, message, notifType)
    elseif Config.Notify == 'ox' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Billing',
            description = message,
            type = notifType 
        })
    elseif Config.Notify == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    elseif Config.Notify == 'mythic' then
        TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = notifType, text = message })
    elseif Config.Notify == 'okok' then
        TriggerClientEvent('okokNotify:Alert', source, 'Billing', message, 5000, notifType)
    end
end


local bills = {}

function loadBillsFromDatabase()
    MySQL.Async.fetchAll('SELECT * FROM billing', {}, function(result)
        for _, bill in pairs(result) do
            bills[bill.id] = {
                citizenId = bill.citizenId,
                amount = bill.amount,
                reason = bill.reason,
                dueTime = bill.dueTime
            }
        end
        print('[BILLING] All bills were successfully loaded from the database.')
    end)
end

-- Panggil fungsi saat server mulai
CreateThread(function()
    Wait(1000) -- Tunggu sebentar sebelum load data
    loadBillsFromDatabase()
end)

RegisterNetEvent('dt_billing:addBill', function(targetId, amount, reason)
    local src = source
    local citizenId
    local playerName

    if Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(targetId)
        if not Player then return end
        citizenId = Player.PlayerData.citizenid
        playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(targetId)
        if not xPlayer then return end
        citizenId = xPlayer.identifier
        playerName = xPlayer.getName()
    else
        citizenId = GetPlayerIdentifier(targetId, 0)
        playerName = GetPlayerName(targetId)
    end

    local dueTime = os.time() + Config.BillingExpireTime

    MySQL.Async.insert('INSERT INTO billing (citizenId, amount, reason, dueTime) VALUES (?, ?, ?, ?)', 
        {citizenId, amount, reason, dueTime},
        function(insertId)
            if insertId then
                bills[insertId] = {
                    citizenId = citizenId,
                    amount = amount,
                    reason = reason,
                    dueTime = dueTime
                }

                -- Log billing baru
                logBilling(playerName, citizenId, amount, reason)

                TriggerClientEvent('dt_billing:refreshBills', targetId)
                sendNotification(src, string.format(Config.NotifyMsg[Config.Locale].bill_given, amount), 'success')
            end
        end
    )
end)

RegisterNetEvent('dt_billing:payBill', function(billId)
    local src = source
    local citizenId
    local playerName

    if Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end
        citizenId = Player.PlayerData.citizenid
        playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        citizenId = xPlayer.identifier
        playerName = xPlayer.getName()
    else
        citizenId = GetPlayerIdentifier(src, 0)
        playerName = GetPlayerName(src)
    end

    if not bills[billId] or bills[billId].citizenId ~= citizenId then
        sendNotification(src, Config.NotifyMsg[Config.Locale].not_enough_money, 'error')
        return
    end

    local billAmount = bills[billId].amount
    local reason = bills[billId].reason -- Ambil alasan dari tagihan

    if Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player.Functions.RemoveMoney('bank', billAmount) then
            MySQL.Async.execute('DELETE FROM billing WHERE id = ?', {billId})
            bills[billId] = nil 

            -- Log pembayaran dengan reason dari billing
            logPayment(playerName, citizenId, billAmount, reason)

            -- Kirim update ke client untuk refresh UI billing
            TriggerClientEvent('dt_billing:refreshBills', src)
            sendNotification(src, string.format(Config.NotifyMsg[Config.Locale].bill_paid, billAmount), 'success')
        else
            sendNotification(src, Config.NotifyMsg[Config.Locale].not_enough_money, 'error')
        end
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer.getAccount('bank').money >= billAmount then
            MySQL.Async.execute('DELETE FROM billing WHERE id = ?', {billId})

            xPlayer.removeAccountMoney('bank', billAmount)
            bills[billId] = nil 

            -- Log pembayaran dengan reason dari billing
            logPayment(playerName, citizenId, billAmount, reason)

            -- Kirim update ke client untuk refresh UI billing
            TriggerClientEvent('dt_billing:refreshBills', src)
            TriggerClientEvent('dt_billing:notifyPaid', src, billAmount)
        else
            sendNotification(src, Config.NotifyMsg[Config.Locale].not_enough_money, 'error')
        end
    end
end)

RegisterNetEvent('dt_billing:getBills', function()
    local src = source
    local citizenId

    if Config.Framework == 'qbcore' then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end
        citizenId = Player.PlayerData.citizenid
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        citizenId = xPlayer.identifier
    else
        citizenId = GetPlayerIdentifier(src, 0)
    end

    local playerBills = {}
    for id, bill in pairs(bills) do
        if bill.citizenId == citizenId then
            table.insert(playerBills, {
                id = id,
                amount = bill.amount,
                reason = bill.reason
            })
        end
    end

    TriggerClientEvent('dt_billing:openPayBillMenu', src, playerBills)
end)

CreateThread(function()
    while true do
        Wait(60000) -- Cek setiap 1 menit

        local now = os.time()

        for billId, bill in pairs(bills) do
            if now >= bill.dueTime then
                local playerSource = nil

                if Config.Framework == 'qbcore' then
                    local Player = QBCore.Functions.GetPlayerByCitizenId(bill.citizenId)
                    if Player then
                        playerSource = Player.PlayerData.source
                        Player.Functions.RemoveMoney('bank', bill.amount)
                    end
                elseif Config.Framework == 'esx' then
                    for _, playerId in ipairs(GetPlayers()) do
                        local xPlayer = ESX.GetPlayerFromId(tonumber(playerId))
                        if xPlayer and xPlayer.identifier == bill.citizenId then
                            playerSource = playerId
                            xPlayer.removeAccountMoney('bank', bill.amount)
                            break
                        end
                    end
                end

                if playerSource then
                    sendNotification(playerSource, string.format(Config.NotifyMsg[Config.Locale].bill_expire, bill.amount), 'error')
                end

                print('[BILLING] Billing otomatis terpotong: ' .. bill.citizenId .. ' | $' .. bill.amount)

                -- Kirim log ke Discord menggunakan fungsi baru
                logExpireTime(bill.citizenId, bill.amount)

                bills[billId] = nil
            end
        end
    end
end)

local webhookQueue = {} -- Tambahkan ini sebelum sendToDiscord

function processWebhookQueue()
    if #webhookQueue == 0 then return end

    local entry = table.remove(webhookQueue, 1)
    PerformHttpRequest(entry.webhook, function(statusCode, response, headers)
        if statusCode ~= 200 and statusCode ~= 204 then
            print("[WEBHOOK ERROR] Gagal mengirim webhook! Status: " .. tostring(statusCode))
        end
    end, "POST", entry.payload, {["Content-Type"] = "application/json"})

    SetTimeout(2000, processWebhookQueue)
end

function sendToDiscord(title, description, color, webhook)
    if not webhook or webhook == "" then 
        return 
    end

    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color,
            ["footer"] = { ["text"] = os.date("%Y-%m-%d %H:%M:%S") }
        }
    }

    local payload = json.encode({username = "Billing Log", embeds = embed})

    table.insert(webhookQueue, {webhook = webhook, payload = payload})
    processWebhookQueue()
end

function logBilling(playerName, citizenId, amount, reason)
    local locale = Config.Locale or "id" -- Default ke "id" jika tidak ada
    local msg = Config.MsgWebhook[locale]

    sendToDiscord(msg.title1, 
        string.format("**%s:** %s\n**%s:** %s\n**%s:** $%d\n**%s:** %s", 
            msg.title2, playerName, 
            msg.title3, citizenId, 
            msg.title4, amount, 
            msg.title5, reason
        ), 
        16776960, Config.BillingWebhook
    )
end

function logPayment(playerName, citizenId, amount, reason)
    local locale = Config.Locale or "id"
    local msg = Config.MsgWebhook[locale]

    sendToDiscord(msg.title6, 
        string.format("**%s:** %s\n**%s:** %s\n**%s:** $%d\n**%s:** %s", 
            msg.title2, playerName, 
            msg.title3, citizenId, 
            msg.title4, amount, 
            msg.title5, reason
        ), 
        16711680, Config.PaymentWebhook
    )
end

function logExpireTime(citizenId, amount)
    local locale = Config.Locale or "id"
    local msg = Config.MsgWebhook[locale]

    sendToDiscord("Billing Otomatis Terpotong", 
        string.format("**%s:** %s\n**%s:** $%d\n**Status:** Terpotong otomatis karena jatuh tempo", 
            msg.title3, citizenId, 
            msg.title4, amount
        ), 
        16744448, Config.ExpireWebhook
    )
end
