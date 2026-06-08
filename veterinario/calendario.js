const timeButtonsContainer =
    document.getElementById("time-buttons");

const selectedTimeSpan =
    document.getElementById("selected-time-span");

const calendarInput =
    document.getElementById("calendar-input");

let selectedDate = "";
let selectedTime = "";

const hours = [
    "09:00:00",
    "10:00:00",
    "11:00:00",
    "12:00:00",
    "13:00:00",
    "16:00:00",
    "17:00:00",
    "18:00:00"
];

window.onload = () => {

    loadMascotas();

};

function loadMascotas() {

    const idTutor =
        document.getElementById("ID_TUTOR").value;

    const selectMascota =
        document.getElementById("ID_MASCOTA");

    selectMascota.innerHTML = "";

    fetch(
        `getMascotasTutor.jsp?id_tutor=${idTutor}`
    )
    .then(r => r.json())
    .then(mascotas => {

        mascotas.forEach(m => {

            let option =
                document.createElement("option");

            option.value = m.id;
            option.textContent = m.nombre;

            selectMascota.appendChild(option);

        });

    })
    .catch(err => {

        console.error(err);

    });

}

if(calendarInput){

    calendarInput.addEventListener(
        "change",
        e => {

            selectedDate = e.target.value;

            selectedTime = "";

            selectedTimeSpan.textContent =
                "Ninguna";

            loadHours();

        }
    );

}

function loadHours(){

    if(!selectedDate){
        return;
    }

    const idVete =
        document.getElementById("ID_VETE").value;

    timeButtonsContainer.innerHTML = "";

    fetch(
        `getHoras.jsp?fecha=${selectedDate}&id_vete=${idVete}`
    )
    .then(r => r.json())
    .then(horasOcupadas => {

        hours.forEach(hour => {

            let btn =
                document.createElement("button");

            btn.type = "button";

            btn.className = "btn-hora";

            btn.textContent =
                hour.substring(0,5);

            if(horasOcupadas.includes(hour)){

                btn.disabled = true;

                btn.classList.add("ocupado");

            }

            btn.onclick = () => {

                selectedTime = hour;

                selectedTimeSpan.textContent =
                    hour.substring(0,5);

                document
                    .querySelectorAll(
                        "#time-buttons button"
                    )
                    .forEach(b =>
                        b.classList.remove(
                            "selected-hour"
                        )
                    );

                btn.classList.add(
                    "selected-hour"
                );

            };

            timeButtonsContainer.appendChild(
                btn
            );

        });

    });

}

function confirmCita(){

    if(!selectedDate || !selectedTime){

        alert(
            "Selecciona una fecha y una hora."
        );

        return;

    }

    const idTutor =
        document.getElementById("ID_TUTOR").value;

    const idMascota =
        document.getElementById("ID_MASCOTA").value;

    const idVete =
        document.getElementById("ID_VETE").value;

    const data =
        new URLSearchParams();

    data.append(
        "fecha",
        selectedDate
    );

    data.append(
        "hora",
        selectedTime
    );

    data.append(
        "id_tutor",
        idTutor
    );

    data.append(
        "id_vete",
        idVete
    );

    data.append(
        "id_mascota",
        idMascota
    );

    fetch(
        "guardarCita.jsp",
        {
            method:"POST",
            headers:{
                "Content-Type":
                "application/x-www-form-urlencoded"
            },
            body:data.toString()
        }
    )
    .then(r => r.text())
    .then(res => {

        const respuesta =
            res.trim();

        if(respuesta==="OK"){

            alert(
                "Cita registrada correctamente."
            );

            window.location.href =
                "listarCitas.jsp";

        }
        else if(
            respuesta==="DUPLICADO"
        ){

            alert(
                "Ese horario ya está ocupado."
            );

        }
        else{

            alert(
                "Error: " +
                respuesta
            );

        }

    })
    .catch(err => {

        console.error(err);

        alert(
            "Error al guardar."
        );

    });

}