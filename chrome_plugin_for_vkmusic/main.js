const nullthrows = (v) => {
    if (v == null) throw new Error("it's a null");
    return v;
}

function injectCode(src) {
    const script = document.createElement('script');

    script.src = src;
    script.onload = function() {
        console.log("[VKM LNOW] script injected");
        this.remove();
    };

    nullthrows(document.head || document.documentElement).appendChild(script);
}
// Почти всё что выше - код со stackoverflow, т.е писал не я, и мне лень разбираться в том как он работает

(async function (){
    const baseURL = localStorage.getItem("vkmlnow_baseurl_api");
    const KEY = localStorage.getItem("vkmlnow_basekey_api");
    const RES = localStorage.getItem("vkmlnow_reset");

    // Первая настройка, ключа и URL для API
    if (!KEY || !baseURL || RES === "1") {
        console.log("[VKM LNOW] No baseurl or key, maybe first session, send prompt...")

        let auth_data = await (await fetch("https://nowplayingapi.yoricya.ru/generate")).json()

        let key = prompt("Hello! This is VKM Listening Now Plugin. Please set your PRIVATE key for API (or click OK to continue with generated key):", auth_data.key);

        if (!key || key.trim() === "") {
            console.log("[VKM LNOW] Key is empty. Plugin disabled.")
            alert("Key is empty! VKM Listening Now Plugin disabled.")
            return
        }

        let baseurl = prompt("And you can also change the API host (if you don’t want to change or don’t understand what it is - do not change the field and click OK): ", "https://nowplayingapi.yoricya.ru/");

        if (!baseurl || baseurl.trim() === "") {
            console.log("[VKM LNOW] Set default API host")
            baseurl = "https://nowplayingapi.yoricya.ru/"
        }

        if (!baseurl.endsWith("/")) baseurl += "/"

        if (key !== auth_data.key) {
            let f = await fetch(baseurl+"key/"+key)
            let j =  await f.json()

            if (!f.ok) {
                console.log(`[VKM LNOW] Server returned error (${j.code}): `+ j.message)
                console.log(`[VKM LNOW] Used server: ${baseurl}`)
                console.log(`[VKM LNOW] Plugin disabled.`)
                alert(`Server returned error (${j.code}): `+ j.message)
                return
            }

            auth_data = j
        }

        localStorage.setItem("vkmlnow_baseurl_api", baseurl);
        localStorage.setItem("vkmlnow_basekey_api", key);

        localStorage.setItem("vkmlnow_inject_time", 0);
        localStorage.setItem("vkmlnow_reset", "0");

        console.log(`[VKM LNOW] Plugin installed.`)
        console.log(`[VKM LNOW] Used server: ${baseurl}`)
        console.log(`[VKM LNOW] Public token: ${auth_data.token}`)

        alert("VKM Listening Now Plugin installed! Your public API token: "+auth_data.token)
    }

    let it = localStorage.getItem("vkmlnow_inject_time");
    if (Date.now() - it > 60 * 60000){
        window.addEventListener("beforeunload", function(e){
            localStorage.setItem("vkmlnow_inject_time", 0);
        });

        localStorage.setItem("vkmlnow_inject_time", Date.now());
        injectCode(chrome.runtime.getURL('/inject.js'));
    } else
        console.log("[VKM LNOW] script not loaded in new tab!");
})()
