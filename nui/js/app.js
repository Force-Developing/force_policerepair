let currentName = "";

$(document).ready(function() {
    window.addEventListener("message", function(event) {
        let data = event.data
        let action = data.action

        if (action == "OpenRepairMenu") {
            currentName = data.data.playerName

            OpenRepairMenu()
        }

        if (action == "GetEngineHealth") {
            M.toast({html : `Motorhälsa: ${data.data.EngineHealth}`})
        }

    })

    $(document).keydown(function(key) {
        if (key.keyCode == 27) {
            CloseRepairMenu()
        }
    })
})

function OpenRepairMenu() {
    $(`.playerName`).html(`
        <div>Välkommen <span style="font-weight: bold">${currentName}</span>, till polisens reparerings center!</div>
    `);

    $(".container").show(250)
    $.post(`https://force_policerepair/NuiToggle`, JSON.stringify(true))
}

function CloseRepairMenu() {
    M.Toast.dismissAll();

    $(".container").hide(250)
    $.post(`https://force_policerepair/NuiToggle`, JSON.stringify(false))
}

function RepairVehicle() {
    $.post(`https://force_policerepair/RepairVehicle`)
    CloseRepairMenu()
}

function CheckEngineHealth() {
    $.post(`https://force_policerepair/CheckEngine`)
}