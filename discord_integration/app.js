//Pack by: pkg app.js --options expose-gc

const Client = require('@xhayper/discord-rpc').Client;

const BASE_URL = "https://nowplayingapi.yoricya.ru/"; // Base API url
const BASE_TOKEN = "831c7b971560ab624f116753643c1bb44f49c033b1c67582d411bb2b4ac07d61e28d79e24da53dc98e0883df0a7df2db"; // API Token

console.log("Init...")

const client = new Client({
    clientId: "1290636014657863771" //Discord APP ID (Current: VK Music)
});

function login() {
    console.log("Login...")
    client.login().catch(() => {
        console.log("Login rejected. Rejoining after 5 sec")
        stop_all()
        setTimeout(login, 5000)
    });
}

client.on("disconnected", () => {
    console.log("Client disconnected. Rejoining after 5 sec")
    stop_all()
    setTimeout(login, 5000)
});

let fetch_track_interval = null
let update_activity_interval = null
client.on("ready", () => {
    console.log("Client ready!")
    fetch_track_interval = fetch_track();
    update_activity_interval = update_activity();
});

let track = null
function fetch_track(){
    return setInterval(async()=>{
        try {
            let response = await (await fetch(`${BASE_URL}get/${BASE_TOKEN}`)).json().catch(e=>{})

            if (!response.is_playing) {
                track = null
                return
            }

            track = response
        }catch (e){}

    }, 1000)
}

function track_hash(t){
    return t.name+t.author+t.start_timestamp+t.end_timestamp
}

let pid = process.pid
let old_track = ""
function update_activity(){
    return setInterval(async()=> {
        if(track == null) {
            if(old_track !== "") {
                client.user.clearActivity(pid)
                old_track = ""
            }

            return
        }

        let new_track = track_hash(track)
        if(new_track === old_track) return

        old_track = new_track
        console.log(`Track state changed: (Service: ${track.service_name}) ${track.author}: ${track.name} `)

        let a = {
            state: track.author,
            details: track.name,
            type: 2,
            startTimestamp: Number(track.start_timestamp),
            endTimestamp: Number(track.end_timestamp),
            largeImageKey: track.album_image,
        }

        if(track.track_url && track.track_url.trim() !== ""){
            a['buttons'] = [{
                label: "Open in web",
                url: track.track_url
            }]
        }

        client.user.setActivity(a, pid);
    }, 1000)
}

function stop_all() {
    clearInterval(fetch_track_interval)
    clearInterval(update_activity_interval)
    old_track = ""
}

login();
