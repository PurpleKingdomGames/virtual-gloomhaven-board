"use strict";
(() => {
    const app = Elm.Main.init({
        node: document.getElementById("elm-node"),
        flags: [
            JSON.parse(window.localStorage.getItem("state"))
            , generateOverrides()
            , Math.floor(Math.random() * Math.floor(4000))
        ]
    });
    DragPorts.setup(app)

    const conn = new signalR
        .HubConnectionBuilder()
        .withUrl("/ws")
        .configureLogging(signalR.LogLevel.Information)
        .withAutomaticReconnect([0, 3000, 5000, 10000, 15000, 30000])
        .build()
        ;

    let lastGameState = null;
    let roomCode = null;

    conn.onreconnected(() => app.ports.connected.send(null));
    conn.onreconnecting(() => app.ports.reconnecting.send(null));
    conn.onclose(() => app.ports.disconnected.send(null));

    conn.on("RoomCreated", (newRoomCode) => {
        roomCode = newRoomCode;
        app.ports.receiveRoomCode.send(newRoomCode)
    });

    conn.on("InvalidRoomCode", () =>
        app.ports.invalidRoomCode.send(null)
    );

    conn.on("ReceiveGameState", (state) => {
        app.ports.receiveUpdate.send(state)
    });

    conn.on("PushGameState", () => {
        if (lastGameState !== null && roomCode !== null)
            conn
                .invoke("SendGameState", roomCode, lastGameState)
                .catch(err => console.error(err))
                ;
    });

    app.ports.saveData.subscribe((data) =>
        window.localStorage.setItem("state", JSON.stringify(data))
    );

    app.ports.connect.subscribe(async () => {
        if (conn.state === signalR.HubConnectionState.Disconnected) {
            try {
                await conn.start();
                app.ports.connected.send(null);
            } catch (err) {
                console.log(err);
                app.ports.disconnected.send(null);
            }
        }
    });

    app.ports.createRoom.subscribe(seed => {
        if (conn.state === signalR.HubConnectionState.Connected)
            conn
                .invoke("CreateRoom", seed)
                .catch(err => console.error(err))
                ;
    });

    app.ports.joinRoom.subscribe((args) => {
        const oldCode = args[0];
        const newCode = args[1];

        if (oldCode !== null)
            conn.invoke("LeaveRoom", oldCode).catch(err => console.error(err));

        roomCode = newCode;
        conn.invoke("JoinRoom", newCode).catch(err => console.error(err));
    });

    app.ports.sendUpdate.subscribe((args) => {
        lastGameState = args[1];
        conn.invoke("SendGameState", args[0], args[1]).catch(err => console.error(err));
    });

    app.ports.toggleFullscreenPort.subscribe((enabled) => {
        const elem = document.getElementById('content')
        if (enabled && document.fullscreenEnabled && !document.fullscreenElement) {
            elem.requestFullscreen();
            elem.onfullscreenchange = () => {
                if (!document.fullscreenElement)
                    app.ports.exitFullscreen.send(null)
            };
        }
        else if (!enabled && document.fullscreenElement)
            document.exitFullscreen();
    });

    app.ports.getCellFromPoint.subscribe((args) => {
        let elem = document.elementFromPoint(args[0], args[1])
        let i = 0

        while (i++ != 100 && elem != null && elem.className.substring(0, 7) != 'hexagon')
            elem = elem.parentElement

        if (elem == null || elem.className.substring(0, 7) != 'hexagon')
            return;

        app.ports.onCellFromPoint.send([
            parseInt(elem.dataset.cellX),
            parseInt(elem.dataset.cellY),
            args[2]
        ])
    })

    document.addEventListener('paste', (event) => {
        app.ports.onPaste.send((event.clipboardData || window.clipboardData).getData('text'));
        event.preventDefault();
    })

    function generateOverrides() {
        const scenarioId = getUrlParameter('scenario');
        const players = getUrlParameter('players');
        const roomCodeSeed = getUrlParameter('seed');

        let o = {
            initScenario: null,
            initPlayers: null,
            initRoomCodeSeed: null,
            lockScenario: getUrlParameter('lockScenario') === '1',
            lockPlayers: getUrlParameter('lockPlayers') === '1',
            lockRoomCode: getUrlParameter('lockRoomCode') === '1'
        };

        if (scenarioId !== undefined) {
            const id = parseInt(scenarioId);
            if (!isNaN(id))
                o.initScenario = id;
        }

        if (players != undefined)
            o.initPlayers = players.replace(/\s+/g, "").split(',');

        if (roomCodeSeed !== undefined) {
            const seed = parseInt(roomCodeSeed);
            if (!isNaN(seed))
                o.initRoomCodeSeed = seed;
        }

        if (document.referrer !== "") {
            if (document.referrer.includes("gloomhaven-storyline.com")) {
                o.campaignTracker = {
                    name: "Gloomhaven Storyline",
                    url: "https://gloomhaven-storyline.com/tracker/#/story/{scenarioId}"
                }
            }
        }

        return o;
    }

    function getUrlParameter(name) {
        name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
        var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
        var results = regex.exec(location.search);
        return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
    };
})();