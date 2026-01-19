--magic

--not even ffi is present?
if not ffi then return end

_, libcrypto = pcall(ffi.load, "libcrypto")

--doesn't have a dll for libcrypto
if not libcrypto then return end

AES = {}

--relevant declarations from libcrypto
ffi.cdef[[

typedef struct evp_cipher_ctx_st EVP_CIPHER_CTX;
typedef struct evp_cipher_st EVP_CIPHER;
typedef struct engine_st ENGINE;

EVP_CIPHER_CTX *EVP_CIPHER_CTX_new(void);
void EVP_CIPHER_CTX_free(EVP_CIPHER_CTX *c);

int EVP_DecryptInit_ex(EVP_CIPHER_CTX *ctx,
    const EVP_CIPHER *cipher,
    ENGINE *impl /* must be NULL */,
    const unsigned char *key,
    const unsigned char *iv);

int EVP_DecryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out,
    int *outl, const unsigned char *in, int inl);

int EVP_DecryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *outm,
    int *outl);


int EVP_EncryptInit_ex(EVP_CIPHER_CTX *ctx,
    const EVP_CIPHER *cipher,
    ENGINE *impl /* must be NULL */,
    const unsigned char *key,
    const unsigned char *iv);

int EVP_EncryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out,
    int *outl, const unsigned char *in, int inl);

int EVP_EncryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *out,
    int *outl);

const EVP_CIPHER *EVP_aes_256_ecb(void);
const EVP_CIPHER *EVP_aes_256_cbc(void);
const EVP_CIPHER *EVP_aes_256_cfb1(void);
const EVP_CIPHER *EVP_aes_256_cfb8(void);
const EVP_CIPHER *EVP_aes_256_cfb128(void);
//#define EVP_aes_256_cfb EVP_aes_256_cfb128
const EVP_CIPHER *EVP_aes_256_ofb(void);
const EVP_CIPHER *EVP_aes_256_ctr(void);
const EVP_CIPHER *EVP_aes_256_ccm(void);
const EVP_CIPHER *EVP_aes_256_gcm(void);
const EVP_CIPHER *EVP_aes_256_xts(void);

]]

--all keys in ascii (classic and rio are the same)
--taken from angry birds cryptor
AES.Keys = {
    Assets = {
        Classic     = "USCaPQpA4TSNVxMI1v9SK9UC0yZuAnb2",
        Rio         = "USCaPQpA4TSNVxMI1v9SK9UC0yZuAnb2",
        Seasons     = "zePhest5faQuX2S2Apre@4reChAtEvUt",
        Space       = "RmgdZ0JenLFgWwkYvCL2lSahFbEhFec4",
        StarWars    = "An8t3mn8U6spiQ0zHHr3a1loDrRa3mtE",
        StarWars2   = "B0pm3TAlzkN9ghzoe2NizEllPdN0hQni",
        Friends     = "EJRbcWh81YG4YzjfLAPMssAnnzxQaDn1",
        Stella      = "4FzZOae60yAmxTClzdgfcr4BAbPIgj7X", --as if stella would ever be portable
    },

    Saves = {
        Classic     = "44iUY5aTrlaYoet9lapRlaK1Ehlec5i0",
        Rio         = "44iUY5aTrlaYoet9lapRlaK1Ehlec5i0",
        Seasons     = "brU4u=EbR4s_A3APu6U#7B!axAm*We#5",
        Space       = "TpeczKQL07HVdPbVUhAr6FjUsmRctyc5",
        StarWars    = "e83Tph0R3aZ2jGK6eS91uLvQpL33vzNi",
        StarWars2   = "taT3vigDoNlqd44yiPbt21biCpVma6nb",
        Friends     = "XN3OCmUFL6kINHuca2ZQL4gqJg0r18ol",
        Stella      = "Bll3qkcy5fKrNVxZqtkFH19Ojn2sdJFu",
    },

    OnlineAssets = {
        Classic     = "",
        Rio         = "",
        Seasons     = "",
        Space       = "",
        StarWars    = "",
        StarWars2   = "9fICj18BCnclaoPD83JVNX0JD3jdCLqA",
        Friends     = "rF1pFq2wDzgR7PQ94dTFuXww0YvY7nfK",
        Stella      = "0xMizJJUh7BbwmYhqxpJ038x8YGvk6aU",
    },
}

--decrypt and encrypt functions were referenced from:
--https://wiki.openssl.org/index.php/EVP_Symmetric_Encryption_and_Decryption
--https://github.com/openresty/lua-resty-string/blob/master/lib/resty/aes.lua

--decrypt a string with a key and optional iv
--angry birds does not use an iv, using 0 as an iv can corrupt the output
--it doesn't get much simpler:
--local dec = decrypt(src, AES.Keys.Assets.Classic, nil)
function AES.Decrypt(ciphertext, key, iv)
    local len = ffi.new("int[1]", 0)
    local plaintext_len = ffi.new("int[1]", 0)

    local plaintext = ffi.new("unsigned char[?]", ciphertext:len())
    
    local ctx = libcrypto.EVP_CIPHER_CTX_new()
    if not (ctx) then return end
    
    if not (libcrypto.EVP_DecryptInit_ex(ctx, libcrypto.EVP_aes_256_cbc(), nil, key, iv) == 1) then return end
    
    if not (libcrypto.EVP_DecryptUpdate(ctx, plaintext, len, ciphertext, ciphertext:len()) == 1) then return end
    plaintext_len[0] = len[0]
    
    if not (libcrypto.EVP_DecryptFinal_ex(ctx, plaintext + len[0], len) == 1) then return end
    plaintext_len[0] = plaintext_len[0] + len[0]
    
    ffi.gc(ctx, libcrypto.EVP_CIPHER_CTX_free)
    
    return ffi.string(plaintext, plaintext_len[0])
end

--same as decrypt but encrypts
--not quite used right now
function AES.Encrypt(plaintext, key, iv)
    local len = ffi.new("int[1]", 0)
    local ciphertext_len = ffi.new("int[1]", 0)

    local ciphertext = ffi.new("unsigned char[?]", plaintext:len() + 64)
    
    local ctx = libcrypto.EVP_CIPHER_CTX_new()
    if not (ctx) then return end
    
    if not (libcrypto.EVP_EncryptInit_ex(ctx, libcrypto.EVP_aes_256_cbc(), nil, key, iv) == 1) then return end
    
    if not (libcrypto.EVP_EncryptUpdate(ctx, ciphertext, len, plaintext, plaintext:len()) == 1) then return end
    ciphertext_len[0] = len[0]
    
    if not (libcrypto.EVP_EncryptFinal_ex(ctx, ciphertext + len[0], len) == 1) then return end
    ciphertext_len[0] = ciphertext_len[0] + len[0]
    
    ffi.gc(ctx, libcrypto.EVP_CIPHER_CTX_free)
    
    return ffi.string(ciphertext, ciphertext_len[0])
end

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