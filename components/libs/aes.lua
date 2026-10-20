--interface for aes decryption, handled in lzma_aes.lua as of now


local AES = {}

--all keys in ascii (classic and rio are the same)
--taken from angry birds cryptor
AES.Keys = {
    Assets = {
        ClassicRio  = "USCaPQpA4TSNVxMI1v9SK9UC0yZuAnb2",
        --Rio         = "USCaPQpA4TSNVxMI1v9SK9UC0yZuAnb2",
        Seasons     = "zePhest5faQuX2S2Apre@4reChAtEvUt",
        Space       = "RmgdZ0JenLFgWwkYvCL2lSahFbEhFec4",
        StarWars    = "An8t3mn8U6spiQ0zHHr3a1loDrRa3mtE",
        StarWars2   = "B0pm3TAlzkN9ghzoe2NizEllPdN0hQni",
        Friends     = "EJRbcWh81YG4YzjfLAPMssAnnzxQaDn1",
        Stella      = "4FzZOae60yAmxTClzdgfcr4BAbPIgj7X", --as if stella would ever be portable
    },

    Saves = {
        ClassicRio  = "44iUY5aTrlaYoet9lapRlaK1Ehlec5i0",
        --Rio         = "44iUY5aTrlaYoet9lapRlaK1Ehlec5i0",
        Seasons     = "brU4u=EbR4s_A3APu6U#7B!axAm*We#5",
        Space       = "TpeczKQL07HVdPbVUhAr6FjUsmRctyc5",
        StarWars    = "e83Tph0R3aZ2jGK6eS91uLvQpL33vzNi",
        StarWars2   = "taT3vigDoNlqd44yiPbt21biCpVma6nb",
        Friends     = "XN3OCmUFL6kINHuca2ZQL4gqJg0r18ol",
        Stella      = "Bll3qkcy5fKrNVxZqtkFH19Ojn2sdJFu",
    },

    OnlineAssets = {
        ClassicRio  = "",
        --Rio         = "",
        Seasons     = "",
        Space       = "",
        StarWars    = "",
        StarWars2   = "9fICj18BCnclaoPD83JVNX0JD3jdCLqA",
        Friends     = "rF1pFq2wDzgR7PQ94dTFuXww0YvY7nfK",
        Stella      = "0xMizJJUh7BbwmYhqxpJ038x8YGvk6aU",
    },
}


--looks through all keys inside the given keys table and sees which one can decrypt the file successfully
function AES.FindKey(ciphertext, keys, iv)
    if keys.DefaultKey then
        return keys.DefaultKey
    end

    --default key was not found yet
    for i, key in pairs(keys) do
        if key ~= "" then
            local dec = AES.Decrypt(ciphertext, key, iv)
            if dec and identifySrc(dec) ~= "binary" then
                --no errors were found
                keys.DefaultKey = key
                print("AES.FindKey: selected "..i.." key")

                return key
            end
        end
    end
end

return AES
