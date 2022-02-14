"use strict";
(() => {
    const app = Elm.Creator.init({
        node: document.getElementById("elm-node"),
        flags: JSON.parse(window.localStorage.getItem("creator"))

    });
    DragPorts.setup(app);

    app.ports.getConfirmCreateNew.subscribe(() => {
        if (window.confirm('Create a new Scenario? Any data not exported will be lost'))
            app.ports.onConfirmCreateNew.send(null)
    })

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
    });

    app.ports.saveMapData.subscribe((data) => {
        window.localStorage.setItem("creator", JSON.stringify(data))
    });

    app.ports.getContextPosition.subscribe((args) => {
        let elem = document
            .querySelector("[data-cell-x='" + args[0] + "'][data-cell-y='" + args[1] + "']")
            ;

        let contextMenus = document.getElementsByClassName('context-menu');

        if (elem == null || contextMenus == null || contextMenus.length == 0 || elem.className.substring(0, 7) != 'hexagon')
            return;

        let contextMenu = contextMenus[0];
        let compare = elem;
        let offsetX = elem.offsetLeft;
        let offsetY = elem.offsetTop;
        do {
            compare = compare.offsetParent;

            offsetX += compare.offsetLeft;
            offsetY += compare.offsetTop;
        } while (!compare.offsetParent.classList.contains('board-wrapper'))

        offsetY += 25;
        offsetX += parseInt(contextMenu.clientWidth / 4);

        // compare is now the row
        let wrapper = compare.offsetParent;

        offsetX -= wrapper.scrollLeft;
        offsetY -= wrapper.scrollTop;

        if (offsetX + contextMenu.clientWidth > wrapper.scrollWidth)
            offsetX -= parseInt((contextMenu.clientWidth / 2) + parseInt(contextMenu.clientWidth / 4))

        if (offsetY + contextMenu.clientHeight > wrapper.scrollHeight)
            offsetY -= contextMenu.clientHeight

        app.ports.onContextPosition.send([offsetX, offsetY]);
    });
})();