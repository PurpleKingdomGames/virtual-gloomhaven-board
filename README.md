# Virtual Gloomhaven Board
The Virtual Gloomhaven Board is designed to help people to play Gloomhaven remotely, without the need for a physical board.

## Getting Started

### Installation
You can find the latest release [here](https://github.com/PurpleKingdomGames/virtual-gloomhaven-board/releases/latest). Simply download the binary for your operating
system (Windows, Mac, and Linux are all supprted), and then run that program (for Mac and Windows users simply double click, Linux users may need to run it
from a terminal). This will start the application listening on port 5000 by default. You can test it's working by going to `http://localhost:5000` in the browser of your
choice (currently Firefox, Chrome and Edge are supported).

### Port Forwarding
Once set up it's time to let others play with you! For this you will need to use port forwarding to send all traffic on port `5000` to your IP address. This can be
tricky if you haven't done it before as it requires you to change your router settings. Each manufacturer is different so you'll need to look up exact details
for the router you have, but the steps are broadly the same:
 * Log into your router
 * Navigate to the Port Forwarding (sometimes called Virtual Server) section in the menu
 * Set up all incoming TCP traffic on port 5000 to forward to your *internal* IP on port 5000

### Connecting Externally
With those setting complete, other people should now be able to use your Virtual Board! Find your *exteneral* IP address (you can use a site such as
[this](https://www.whatsmyip.org/)) and then ask your friends to open a browser and navigate to `http://<YOUR_IP>:5000` (where `<YOUR_IP>` is your *external* IP
adddress).

### Room Codes
At this stage you will all be connected with randomly generated room codes. The room code is shown in the top right, and needs to be the same for everyone who wants
to join your game. Share your room code via a chat app, SMS, email, or [carrier pigeon](https://tools.ietf.org/html/rfc2549) and ask everyone to change to that code.
The room code can be changed by using the menu icon in the top left, and selecting `Connection Settings`. If you're streaming or recording your game then you may want
to hide your room code using the same menu.

## Useful Additional Software
Playing with a virtual board is fun, but to really get the (remote) party going we recomend the following additional software:
* A chat application such as [Jitsi Meet](https://meet.jit.si/), [Zoom](https://zoom.us/), [Discord](https://discord.com/),
or [Google Meet](https://meet.google.com/)
* The offical [Gloomhaven Helper](http://esotericsoftware.com/gloomhaven-helper)
* The online [Gloomhaven Scenario Book](https://online.flippingbook.com/view/145446/)
* The [Gloomhaven Battle Goals Generator](http://rastrillo.synology.me:3838/)
* The [Gloomhaven Party Tracker](https://ninjalooter.de/gloomhaven/party)
