// Основная логика парсинга и дальнейшей отправки треков на апи
(async function(){
    const baseURL = localStorage.getItem("vkmlnow_baseurl_api");
    const KEY = localStorage.getItem("vkmlnow_basekey_api");

    if (!KEY || !baseURL) {
        console.log("[VKM LNOW INJ] No baseurl or key.")
        return
    }

    let oldTrackName = "";
    let oldTrackEndTime = 0;
    let oldTrackStartTime = 0;
    async function upTrack(trackObject){
        if(trackObject == null){
            if(oldTrackName != null){
                oldTrackName = null;
                await sendTrack(null);
            }
            return;
        }

        if(oldTrackName !== trackObject.name || ((trackObject.endTime - oldTrackEndTime) / 1000) > 2 || ((trackObject.endTime - oldTrackEndTime) / 1000) < -2){ // Я сам не до конца понимаю как это работает
            oldTrackName = trackObject.name;
            oldTrackEndTime = trackObject.endTime;
            oldTrackStartTime = trackObject.startTime;

            await sendTrack(trackObject);
        }
    }

    async function sendTrack(trackObject){
        let params
        if(trackObject != null){
            params = new URLSearchParams({
                service_name: "VK Music",
                name: trackObject.name,
                author: trackObject.author,
                album_image: trackObject.albumImageUrl,
                track_url: trackObject.url,
                album_name: "",
                start_timestamp: trackObject.startTime,
                end_timestamp: trackObject.endTime,
            }).toString();
            await fetch(`${baseURL}set/${KEY}?${params}`); //Send music activity
        }else{
            await fetch(`${baseURL}set/${KEY}`); //Reset activity
        }
    }

    function htmlDecode(input) {
        let doc = new DOMParser().parseFromString(input, "text/html");
        return doc.documentElement.textContent;
    }

    setInterval(()=>{
        let Player = getAudioPlayer(); // Функция определена на странице VK
        let isPlaying = !Player._isPaused && Player._isPlaying && !Player.ads._isActive;

        if(isPlaying){
            const CurrentAudio = Player._currentAudio;

            let audioObject = {};

            audioObject.name = (() => {
                if(CurrentAudio[16])
                    return htmlDecode(CurrentAudio[3] + " - "+CurrentAudio[16]);
                else
                    return htmlDecode(CurrentAudio[3]);
            })()

            audioObject.author = htmlDecode(CurrentAudio[4]);

            let allTime = CurrentAudio[5];
            let curTime = Player.stats.currentPosition;

            audioObject.startTime = Math.floor((Date.now() - (curTime * 1000)) / 1000) * 1000; // Да кто знает как оно работает :peepoChill:
            audioObject.endTime = audioObject.startTime + allTime * 1000;

            audioObject.albumImageUrl = (() => {
                if(CurrentAudio[14])
                    return CurrentAudio[14].split(",")[0];
                else
                    return "";
            })()

            audioObject.url = (() => {
                if(CurrentAudio[26])
                    return "https://vk.com/audio"+CurrentAudio[26];
                else
                    return "";
                    // return "https://vk.com/audio?q="+encodeURI(audioObject.name+" - "+audioObject.author); //Поиск у них всё равно без авторизации не работает
            })()

            upTrack(audioObject);
            return;
        }

        upTrack(null);
    }, 1500)
})()
// VK, только посмейте блznь поменять что-то в getAudioPlayer(). Или откройте тогда наконец-то апи
