<%@ page contentType="text/html;charset=UTF-8" %>
<%
    if (request.getUserPrincipal() != null) {
        if (request.isUserInRole("tutor")) {
            response.sendRedirect("tutor/dashboard.jsp");
        } else if (request.isUserInRole("veterinario")) {
            response.sendRedirect("veterinario/agenda.jsp");
        }
        return;
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Petify – Iniciar sesión</title>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css"/>
</head>
<body>

  <div class="bg-wave"></div>

  <main class="wrapper">
    <div class="logo-block">
      <svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg" class="logo-svg">
        <rect width="80" height="80" rx="18" fill="#1a3d35"/>
        <ellipse cx="40" cy="50" rx="13" ry="11" fill="rgba(255,255,255,.9)"/>
        <ellipse cx="26" cy="37" rx="7"  ry="9"  fill="rgba(255,255,255,.9)"/>
        <ellipse cx="38" cy="32" rx="7"  ry="9"  fill="rgba(255,255,255,.9)"/>
        <ellipse cx="50" cy="32" rx="7"  ry="9"  fill="rgba(255,255,255,.9)"/>
        <ellipse cx="62" cy="37" rx="7"  ry="9"  fill="rgba(255,255,255,.9)"/>
      </svg>
      <span class="logo-name">PETIFY</span>
    </div>


    <div class="card">
      <h2 class="card-title">Iniciar sesión</h2>
      <p class="card-sub">Bienvenido de nuevo</p>

      <% if ("bloqueado".equals(request.getParameter("error"))) { %>
        <p class="error-msg" style="text-align:center; margin-bottom:12px;">
          Demasiados intentos fallidos. Intenta en <%= request.getParameter("min") %> minuto(s).
        </p>
      <% } else if ("1".equals(request.getParameter("error"))) { %>
        <p class="error-msg" style="text-align:center; margin-bottom:12px;">
          Correo o contraseña incorrectos
        </p>
      <% } %>

      <form method="post" action="${pageContext.request.contextPath}/procesarLogin.jsp">

        <div class="form-group">
          <label for="j_username">Correo electrónico</label>
          <div class="input-wrap">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="2" y="4" width="20" height="16" rx="2"/>
              <path d="M2 7l10 7 10-7"/>
            </svg>
            <input type="email" id="j_username" name="j_username" placeholder="correo@ejemplo.com" autocomplete="email"/>
          </div>
        </div>

        <div class="form-group">
          <label for="j_password">Contraseña</label>
          <div class="input-wrap">
            <svg class="input-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
            <input type="password" id="j_password" name="j_password" placeholder="Tu contraseña"/>
          </div>
        </div>

        <button class="btn-acceso" type="submit">Entrar</button>
      </form>
      <div class="links">
        <a href="registroUsuario.html">¿No tienes cuenta? Regístrate</a>
      </div>
    </div>

  </main>

</body>
</html>