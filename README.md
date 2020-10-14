# Virtual Gloomhaven Board
The Virtual Gloomhaven Board is designed to help people to play Gloomhaven remotely,
without the need for a physical board.

## Getting Started

### Using the Hosted Solution
The quickest and easiest way to get up and running is by opening
[vgb.purplekingdomgames.com](https://vgb.purplekingdomgames.com/) in a browser!

### Using a Local Server
If you'd rather use a local server than the online version (perhaps you're playing
ove LAN, or just fancy the technical challenge), then you can do that too!
In essence all you need to do is download the correct file and set up port forwarding,
but more detailed instructions are below:

#### Installation
You can find the latest release
[here](https://github.com/PurpleKingdomGames/virtual-gloomhaven-board/releases/latest).
Simply download the binary for your operating system (Windows, Mac, and Linux are all
supprted), and then run that program (fWindows users simply double click, Mac and Linux
users may need to grant executable privileges and run it from a terminal). This will
start the application listening on port 5000 by default. You can test it's working
by going to `http://localhost:5000` in the browser of your choice (currently
Firefox, Chrome and Edge are supported).

#### Port Forwarding
Once set up it's time to let others play with you! For this you will need to use
port forwarding to send all traffic on port `5000` to your IP address. This can be
tricky if you haven't done it before as it requires you to change your router
settings. Each manufacturer is different so you'll need to look up exact details
for the router you have, but the steps are broadly the same:
 * Log into your router
 * Navigate to the Port Forwarding (sometimes called Virtual Server) section in the menu
 * Set up all incoming TCP traffic on port 5000 to forward to your *internal* IP on port 5000

#### Connecting Externally
With those setting complete, other people should now be able to use your Virtual
Board! Find your *exteneral* IP address (you can use a site such as
[this](https://www.whatsmyip.org/)) and then ask your friends to open a browser
and navigate to `http://<YOUR_IP>:5000` (where `<YOUR_IP>` is your *external* IP
adddress).

### Room Codes
At this stage you will all be connected with randomly generated room codes. The
room code is shown in the top left, and needs to be the same for everyone who wants
to join your game. Share your room code via a chat app, SMS, email, or
[carrier pigeon](https://tools.ietf.org/html/rfc2549) and ask everyone to change to
that code. The room code can be changed by using the menu icon in the top left,
and selecting `Settings`. If you're streaming or recording your game
then you may want to hide your room code using the same menu.

### Adding Players
Player characters can be added, removed, and changed by clicking the menu icon in
the top left and selecting `Change Players`. Clicking on a character icon will
select it, bringing that icon into full colour (except for the Triforce icon,
which is always grey, but does get a lovely shadow effect). Once you're happy
with your selection, click 'OK'.

## Customisation
In situations where you're self-hosting or linking through a third paty you may
want to lock some of the components, or start players off with a certain configuration.
For that you can use [query string parameters](https://en.wikipedia.org/wiki/Query_string),
of which the following are supported:
 * scenario - An integer between 1 and 96 denoting the starting scenario
 * players - A comma-seperated list of icon names representing players. Valid values are:
    * brute
    * tinkerer
    * scoundrel
    * cragheart
    * mindthief
    * spellweaver
    * phoenix-face
    * lightning-bolt
    * angry-face
    * triforce
    * eclipse
    * cthulhu
    * three-spears
    * saw
    * music-note
    * concentric-circles
    * sun
 * seed - An integer between 0 and 2,147,483,647 used to generate the initial room code
 * lockScenario - If provided should be 1. Stops players changing the scenario
 * lockPlayers - If provided should be 1. Stops players changing the characters in the game
 * lockRoomCode - If provided should be 1. Stops players changing the room code

## Useful Additional Software
Playing with a virtual board is fun, but to really get the (remote) party going we recomend the following additional software:
* A chat application such as [Jitsi Meet](https://meet.jit.si/), [Zoom](https://zoom.us/), [Discord](https://discord.com/),
or [Google Meet](https://meet.google.com/)
* The offical [Gloomhaven Helper](http://esotericsoftware.com/gloomhaven-helper)
* The online [Gloomhaven Scenario Book](https://online.flippingbook.com/view/145446/)
* The [Gloomhaven Battle Goals Generator](http://rastrillo.synology.me:3838/)
* The [Gloomhaven Party Tracker](https://ninjalooter.de/gloomhaven/party)
