var DragPorts = (function () {
    // data must be of the format:
    // { effectAllowed: string, event: DragEvent }
    function processDragStart(data) {
        if (data.event.dataTransfer !== null) {
            data.event.dataTransfer.setData("text/plain", null); // needed
            data.event.dataTransfer.effectAllowed = data.effectAllowed;

            let emptyImage = document.createElement('img');
            // Set the src to be a 0x0 gif
            emptyImage.src = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==';
            data.event.dataTransfer.setDragImage(emptyImage, 0, 0);
        }
    }

    // data must be of the format:
    // { dropEffect: string, event: DragEvent }
    function processDragOver(data) {
        if (data.event.dataTransfer !== null)
            data.event.dataTransfer.dropEffect = data.dropEffect;
    }

    // Automatic setup of standard drag ports subscriptions.
    function setup(elmApp) {
        elmApp.ports.dragstart.subscribe(processDragStart);
        elmApp.ports.dragover.subscribe(processDragOver);
    }

    return {
        processDragStart: processDragStart,
        processDragOver: processDragOver,
        setup: setup
    };
})();