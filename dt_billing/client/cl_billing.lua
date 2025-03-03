local QBCore = nil
local ESX = nil

if Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

local function GetPlayerJob()
    if Config.Framework == 'qbcore' then
        return QBCore.Functions.GetPlayerData().job.name
    elseif Config.Framework == 'esx' then
        return ESX.GetPlayerData().job.name
    else
        return nil
    end
end

local function IsJobAllowed(job)
    for _, allowedJob in ipairs(Config.JobsBilling) do
        if job == allowedJob then
            return true
        end
    end
    return false
end

local function Notify(type, key, ...)
    local msg = Config.NotifyMsg[Config.Locale][key]
    if msg then
        msg = string.format(msg, ...)
    else
        msg = "Pesan tidak ditemukan!"
    end

    if Config.Notify == 'ox' then
        lib.notify({ title = 'Billing', description = msg, type = type })
    elseif Config.Notify == 'qb' then
        QBCore.Functions.Notify(msg, type)
    elseif Config.Notify == 'esx' then
        ESX.ShowNotification(msg)
    elseif Config.Notify == 'okok' then
        exports['okokNotify']:Alert("Billing", msg, 5000, type)
    elseif Config.Notify == 'mythic' then
        exports['mythic_notify']:DoHudText(type, msg)
    else
        print("Notifikasi tidak dikenali:", msg)
    end
end

RegisterNetEvent('dt_billing:openMenu', function()
    local playerJob = GetPlayerJob()
    
    if not playerJob or not IsJobAllowed(playerJob) then
        Notify('error', 'error_job')
        return
    end

    local input = lib.inputDialog(Config.OpenMenu.tittle1, {
        {type = 'number', label = Config.OpenMenu.tittle2, placeholder = '1'},
        {type = 'number', label = Config.OpenMenu.tittle3, placeholder = '1000'},
        {type = 'input', label = Config.OpenMenu.tittle4, placeholder = 'Bill'}
    })

    if not input or not input[1] or not input[2] or not input[3] then return end

    local targetId = tonumber(input[1])
    local amount = tonumber(input[2])
    local reason = input[3]

    if targetId and amount and amount > 0 then
        TriggerServerEvent('dt_billing:addBill', targetId, amount, reason)
    else
        Notify('error', 'error_input')
    end
end)

RegisterNetEvent('dt_billing:refreshBills', function()
    TriggerServerEvent('dt_billing:getBills')
end)

RegisterNetEvent('dt_billing:openPayBillMenu', function(bills)
    if not bills or #bills == 0 then
        Notify('info', 'no_bills')
        return
    end

    local options = {}
    for _, bill in ipairs(bills) do
        table.insert(options, {
            label = string.format("💰 %s - $%d", bill.reason, bill.amount),
            value = bill.id
        })
    end

    local choice = lib.inputDialog(Config.OpenBill.tittle1, {
        {type = 'select', label = Config.OpenBill.tittle2, options = options}
    })

    if choice and choice[1] then
        local billId = tonumber(choice[1])
        TriggerServerEvent('dt_billing:payBill', billId)
    end
end)

RegisterNetEvent('dt_billing:notifyPaid', function(amount)
    Notify('success', 'bill_paid', amount)
end)

RegisterNetEvent('dt_billing:notifyGiven', function(amount)
    Notify('info', 'bill_given', amount)
end)

RegisterNetEvent('dt_billing:notifyError', function()
    Notify('error', 'not_enough_money')
end)

RegisterCommand("billing", function()
    TriggerEvent('dt_billing:openMenu')
end, false)

RegisterCommand("paybilling", function()
    TriggerServerEvent('dt_billing:getBills')
end, false)
