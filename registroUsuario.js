const get = id => document.getElementById(id);
const err = id => get(`err-${id}`);

function setError(id, msg) {
  get(id).classList.add("invalid");
  err(id).textContent = msg;
}

function clearError(id) {
  get(id).classList.remove("invalid");
  err(id).textContent = "";
}

const rules = {
  nombre:    v => v.length >= 2 ? null : "Mínimo 2 caracteres.",
  apellidos: v => v.length >= 2 ? null : "Mínimo 2 caracteres.",
  correo:    v => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) ? null : "Correo no válido.",
  telefono:  v => /^\d{10}$/.test(v) ? null : "Debe tener exactamente 10 dígitos.",
  password:  v => v.length >= 6 ? null : "Mínimo 6 caracteres.",
  confirm:   v => v === get("password").value ? null : "Las contraseñas no coinciden.",
};

function validateAll() {
  let valid = true;
  for (const [id, rule] of Object.entries(rules)) {
    const msg = rule(get(id).value.trim());
    if (msg) { setError(id, msg); valid = false; }
    else        clearError(id);
  }
  return valid;
}

// Registro
get("btn-register").addEventListener("click", async () => {
  if (!validateAll()) return;

  const params = new URLSearchParams({
    nombre:    get("nombre").value.trim(),
    apellidos: get("apellidos").value.trim(),
    correo:    get("correo").value.trim(),
    telefono:  get("telefono").value.trim(),
    password:  get("password").value
  });

  try {
    const res = await fetch("registroUsuario.jsp", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: params
    });

    if (res.ok) {
      setTimeout(() => {
        window.location.href = "login.jsp";
      }, 1500);

      const btnRegister = get("btn-register");
      btnRegister.textContent = "Cuenta creada, redirigiendo...";
      btnRegister.disabled = true;
    } else {
      const text = await res.text();
      if (text.includes("email_exists")) {
        setError("correo", "Este correo ya está registrado.");
      } else {
        setError("correo", "Error al crear la cuenta, intenta de nuevo.");
      }
    }
  } catch (e) {
    setError("correo", "Error de conexión.");
  }
});

// Limpiar errores al escribir
Object.keys(rules).forEach(id => {
  get(id).addEventListener("input", () => clearError(id));
});

// Toggle contraseña
document.querySelectorAll(".toggle-pass").forEach(btn => {
  btn.addEventListener("click", () => {
    const input  = get(btn.dataset.target);
    const isPass = input.type === "password";
    input.type   = isPass ? "text" : "password";
    btn.querySelector(".eye-open").style.display  = isPass ? "none" : "";
    btn.querySelector(".eye-closed").style.display = isPass ? "" : "none";
  });
});

document.addEventListener("keydown", e => {
  if (e.key === "Enter") get("btn-register").click();
});

// Verificar correo duplicado
if (res.status === 409) {
    setError("correo", "Este correo ya está registrado.");
} else {
    setError("correo", "Error al crear la cuenta, intenta de nuevo.");
}