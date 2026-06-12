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

const dominiosPermitidos = new Set([
  "gmail.com",
  "hotmail.com","hotmail.es","hotmail.com.mx",
  "outlook.com","outlook.es","outlook.com.mx",
  "yahoo.com","yahoo.es","yahoo.com.mx",
  "icloud.com","me.com",
  "live.com","live.com.mx","live.es",
  "msn.com",
  "protonmail.com","proton.me",
  "aol.com",
  "petify.com"
]);

function validarCorreo(v) {
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)) return "Correo no válido.";
  const dominio = v.split("@")[1].toLowerCase();
  if (!dominiosPermitidos.has(dominio)) return "Solo se permiten correos de proveedores conocidos.";
  return null;
}

// Password requirements
const passwordReqs = [
  { id: "req-length",  test: v => v.length >= 8,               label: "Mínimo 8 caracteres" },
  { id: "req-upper",   test: v => /[A-Z]/.test(v),             label: "Al menos 1 mayúscula" },
  { id: "req-number",  test: v => /[0-9]/.test(v),             label: "Al menos 1 número" },
  { id: "req-special", test: v => /[!@#$%^&*()\-_=+\[\]{};':",.<>?/\\|]/.test(v), label: "Al menos 1 carácter especial (!@#$...)" },
];

function validarPassword(v) {
  const fallidos = passwordReqs.filter(r => !r.test(v));
  if (fallidos.length === 0) return null;
  return "La contraseña no cumple los requisitos de seguridad.";
}

function actualizarIndicador(v) {
  const req = get("password-requisitos");
  if (v.length === 0) {
    req.style.display = "none";
    return;
  }
  req.style.display = "flex";
  passwordReqs.forEach(r => {
    const el = get(r.id);
    if (!el) return;
    const ok = r.test(v);
    el.textContent = (ok ? "✓ " : "✗ ") + r.label;
    el.style.color = ok ? "#2e7d32" : "#c62828";
  });
}

const rules = {
  nombre:    v => v.length >= 2 ? null : "Mínimo 2 caracteres.",
  apellidos: v => v.length >= 2 ? null : "Mínimo 2 caracteres.",
  correo:    v => validarCorreo(v),
  telefono:  v => /^\d{10}$/.test(v) ? null : "Debe tener exactamente 10 dígitos.",
  password:  v => validarPassword(v),
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
      const btnRegister = get("btn-register");
      btnRegister.textContent = "Cuenta creada, redirigiendo...";
      btnRegister.disabled = true;
      setTimeout(() => {
        window.location.href = "login.jsp";
      }, 1500);
    } else {
      const text = await res.text();
      if (text.includes("email_exists")) {
        setError("correo", "Este correo ya está registrado.");
      } else if (text.includes("invalid_domain")) {
        setError("correo", "Solo se permiten correos de proveedores conocidos.");
      } else if (text.includes("weak_password")) {
        setError("password", "La contraseña no cumple los requisitos de seguridad.");
      } else {
        setError("correo", "Error al crear la cuenta, intenta de nuevo.");
      }
    }
  } catch (e) {
    setError("correo", "Error de conexión.");
  }
});

// Indicador de requisitos en tiempo real
get("password").addEventListener("input", () => {
  actualizarIndicador(get("password").value);
  clearError("password");
});

get("password").addEventListener("focus", () => {
  if (get("password").value.length > 0) {
    actualizarIndicador(get("password").value);
  }
});

get("password").addEventListener("blur", () => {
  const v = get("password").value;
  if (passwordReqs.every(r => r.test(v))) {
    get("password-requisitos").style.display = "none";
  }
});

// Limpiar errores al escribir
Object.keys(rules).forEach(id => {
  if (id === "password") return; // manejado por el listener de indicador
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
