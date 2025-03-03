Config = {}

Config.Framework = 'qbcore' -- Framework ( qbcore / esx )
Config.Locale = 'en' -- Locale ( id / en )
Config.Notify = 'qb' -- Notify ( qb / esx / ox / okok / mythic )
Config.BillingExpireTime = 86400 -- 1 day in seconds (24 hours)

--[[ 
    Optional, Function Use Radialmenu :
        dt_billing:openMenu ( open menu billing )
        dt_billing:openPayBillMenu ( open menu pay billing )
    Optional, Use Command :
        /billing ( open menu billing )
        /paybilling ( open menu pay billing )
]]--

--[[You can set which jobs can use the billing menu.]]--
Config.JobsBilling = {
    "police",
    "ambulance",
    "mechanic",
    "burgershot",
    "pemerintah"
}

--[[you can customize your discord webhook]]--
Config.BillingWebhook = "https://discord.com/api/webhooks/1337963790880346163/ygoehJc14gKa32G4vqWLrVmNAJhW5z97OexmUZvs7tjo25qXVa1eA0mptw0nNMdy9tTK"
Config.PaymentWebhook = "https://discord.com/api/webhooks/1337963790880346163/ygoehJc14gKa32G4vqWLrVmNAJhW5z97OexmUZvs7tjo25qXVa1eA0mptw0nNMdy9tTK"
Config.ExpireWebhook = "https://discord.com/api/webhooks/1337963790880346163/ygoehJc14gKa32G4vqWLrVmNAJhW5z97OexmUZvs7tjo25qXVa1eA0mptw0nNMdy9tTK"

--[[You can change the billing menu title, just change the part after the equal symbol.]]--
Config.OpenMenu = {
    tittle1 = "Buat Billing",
    tittle2 = "ID Pemain",
    tittle3 = "Jumlah Billing ($)",
    tittle4 = "Deskripsi"
}

--[[You can change the pay billing menu title, just change the part after the equal symbol.]]--
Config.OpenBill = {
    tittle1 = "Pembayaran Menu",
    tittle2 = "Pilih Billing untuk Dibayar",
}

--[[you can change the notification message in the config below]]--
Config.NotifyMsg = {
    id = {
        error_input = "Input tidak valid!",
        error_job = "Anda tidak memiliki akses untuk membuka menu ini!",
        no_bills = "Tidak ada billing yang harus dibayar!",
        bill_paid = "Billing sebesar $%s telah dibayar!",
        bill_given = "Billing sebesar $%s diberikan ke pemain!",
        bill_expire = "Billing otomatis terpotong sebesar $",
        not_enough_money = "Uang tidak cukup untuk membayar billing!",
    },
    en = {
        error_input = "Invalid input!",
        error_job = "You do not have access to open this menu!",
        no_bills = "No bills to pay!",
        bill_paid = "Bill of $%s has been paid!",
        bill_given = "Bill of $%s has been given to the player!",
        bill_expire = "Billing is automatically deducted by $",
        not_enough_money = "Not enough money to pay the bill!",
    },
}

--[[you can change the webhook message in the config below]]--
Config.MsgWebhook = {
    id = {
        title1 = "Billing Ditambahkan",
        title2 = "Pemain",
        title3 = "Citizen ID",
        title4 = "Jumlah",
        title5 = "Deskripsi",
        title6 = "Pembayaran Dilakukan"
    },
    en = {
        title1 = "Billing Added",
        title2 = "Player",
        title3 = "Citizen ID",
        title4 = "Amount",
        title5 = "Description",
        title6 = "Payment Made"
    },
}