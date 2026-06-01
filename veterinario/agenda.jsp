<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head><title>Agenda veterinario</title></head>
<body>
  <h1>Bienvenido, <%= request.getUserPrincipal().getName() %></h1>
  <a href="../j_spring_security_logout">Cerrar sesión</a>
</body>
</html>