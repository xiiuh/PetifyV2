
const timeButtonsContainer = document.getElementById("time-buttons");
const selectedTimeSpan = document.getElementById("selected-time-span");
const calendarInput = document.getElementById("calendar-input");

// 2. Variables de control global
let selectedDate = "";
let selectedTime = "";

// Lista base de horarios de la clínica (Ajusta los horarios según lo necesites)
const hours = [
    "09:00:00", "10:00:00", "11:00:00", "12:00:00",
    "13:00:00", "16:00:00", "17:00:00", "18:00:00"
];

// Escuchar los cambios en el input de fecha (si usas el tipo date del JSP anterior)
if (calendarInput) {
    // Bloquear fechas pasadas
    const _hoy = new Date();
    const _yyyy = _hoy.getFullYear();
    const _mm   = String(_hoy.getMonth() + 1).padStart(2, '0');
    const _dd   = String(_hoy.getDate()).padStart(2, '0');
    calendarInput.min = `${_yyyy}-${_mm}-${_dd}`;

    calendarInput.addEventListener("change", (e) => {
        selectedDate = e.target.value; // Guarda la fecha en formato YYYY-MM-DD
        selectedTime = ""; // Reseteamos la hora si cambia de día
        if (selectedTimeSpan) selectedTimeSpan.textContent = "Ninguna";
        loadHours();
    });
}

// 3. Cargar horas desde el servidor
function loadHours() {
    if (!timeButtonsContainer) return;
    timeButtonsContainer.innerHTML = "";

    const idVete = document.getElementById("ID_VETE").value;
    if (!selectedDate || !idVete) return;

    // NOTA: Verifica si necesitas el "../" dependiendo de la ubicación de getHoras.jsp
    fetch(`getHoras.jsp?fecha=${selectedDate}&id_vete=${idVete}`)
        .then(r => r.json())
        .then(horasOcupadas => {
            hours.forEach(hour => {
                let btn = document.createElement("button");
                btn.textContent = hour.substring(0, 5); // Muestra solo "09:00" en el botón
                btn.type = "button"; // Evita que un formulario se envíe por accidente
                btn.className = "btn-hora"; // Clase base para tus estilos CSS

                // Si la hora de la lista coincide con una ocupada (comparando strings exactos)
                if (horasOcupadas.includes(hour)) {
                    btn.classList.add("ocupado");
                    btn.disabled = true;
                }

                btn.onclick = () => {
                    selectedTime = hour.substring(0, 5); // Enviamos "HH:mm" que es lo que valida el servidor
                    if (selectedTimeSpan) selectedTimeSpan.textContent = hour.substring(0, 5);
                    
                    document.querySelectorAll("#time-buttons button")
                            .forEach(b => b.classList.remove("selected-hour"));
                    btn.classList.add("selected-hour");
                };

                timeButtonsContainer.appendChild(btn);
            });
        })
        .catch(err => console.error("Error cargando horas:", err));
}

// 4. Confirmar y enviar la Cita
function confirmCita() {
    if (!selectedDate || !selectedTime) {
        alert("Selecciona una fecha y una hora antes de confirmar.");
        return;
    }

    // Declaración correcta con const de las variables locales
    const idTutor = parseInt(document.getElementById("ID_TUTOR").value);
    const idVeteVal = parseInt(document.getElementById("ID_VETE").value);
    const idMascota = parseInt(document.getElementById("ID_MASCOTA").value);

    if (isNaN(idTutor) || isNaN(idVeteVal) || isNaN(idMascota)) {
        alert("Datos incompletos, verifica los campos.");
        return;
    }

    const data = new URLSearchParams();
    data.append("fecha", selectedDate);
    data.append("hora", selectedTime);
    data.append("id_tutor", idTutor);
    data.append("id_vete", idVeteVal);
    data.append("id_mascota", idMascota);

    fetch("guardarCita.jsp", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: data.toString()
    })
    .then(r => r.text())
    .then(respuesta => {
        // .trim() evita problemas con espacios en blanco invisibles generados por el JSP
        const resClean = respuesta.trim(); 
        
        if (resClean.includes("OK")) {
            alert("Cita registrada correctamente.");
            window.location.href = "listarCitas.jsp";
        } else if (resClean.includes("DUPLICADO")) {
            alert("Esta hora ya está ocupada para este veterinario.");
        } else if (resClean.includes("SQL_ERROR")) {
            alert("Error SQL: " + resClean);
        } else {
            alert("Respuesta inesperada: " + resClean);
        }
    })
    .catch(err => {
        console.error(err);
        alert("Error al guardar la cita.");
    });
}