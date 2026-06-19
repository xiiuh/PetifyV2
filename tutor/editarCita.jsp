<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String correo = request.getUserPrincipal().getName();
    int idCita;
    try {
        idCita = Integer.parseInt(request.getParameter("id"));
    } catch (Exception e) {
        response.sendRedirect("listarCitas.jsp");
        return;
    }

    Context ctx = new javax.naming.InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    // Obtener id_tutor
    PreparedStatement ps = con.prepareStatement("SELECT id_tutor FROM tutor WHERE correo = ?");
    ps.setString(1, correo);
    ResultSet rs = ps.executeQuery();
    int idTutor = 0;
    if (rs.next()) idTutor = rs.getInt("id_tutor");
    rs.close(); ps.close();

    // Cargar cita verificando que pertenece al tutor
    ps = con.prepareStatement(
        "SELECT c.*, m.nombre AS mascota, v.nom_vete AS veterinario " +
        "FROM citas c " +
        "JOIN mascota m ON c.id_mascota = m.id_mascota " +
        "JOIN veterinario v ON c.id_vete = v.id_vete " +
        "WHERE c.id_citas = ? AND c.id_tutor = ?"
    );
    ps.setInt(1, idCita);
    ps.setInt(2, idTutor);
    rs = ps.executeQuery();

    if (!rs.next()) {
        rs.close(); ps.close(); con.close();
        response.sendRedirect("listarCitas.jsp");
        return;
    }

    String fechaActual = rs.getString("fecha");
    String horaActual  = rs.getString("hora");
    int idVeteActual   = rs.getInt("id_vete");
    int idMascotaActual = rs.getInt("id_mascota");
    rs.close(); ps.close();

    // Procesar POST
    String mensaje = null;
    if ("POST".equals(request.getMethod())) {
        String nuevaFecha     = request.getParameter("fecha");
        String nuevaHora      = request.getParameter("hora");
        String nuevoIdVete    = request.getParameter("id_vete");
        String nuevoIdMascota = request.getParameter("id_mascota");

        java.util.Set<String> horasOk = new java.util.HashSet<>(java.util.Arrays.asList(
            "09:00","10:00","11:00","12:00","13:00","16:00","17:00","18:00"
        ));

        if (nuevaFecha == null || nuevaHora == null || nuevoIdVete == null || nuevoIdMascota == null) {
            mensaje = "error:Parámetros inválidos.";
        } else if (!horasOk.contains(nuevaHora)) {
            mensaje = "error:Hora no válida.";
        } else {
            // Verificar duplicado excluyendo la cita actual
            ps = con.prepareStatement(
                "SELECT COUNT(*) FROM citas WHERE fecha = ? AND hora = ? AND id_vete = ? AND id_citas != ?"
            );
            ps.setString(1, nuevaFecha);
            ps.setString(2, nuevaHora);
            ps.setInt(3, Integer.parseInt(nuevoIdVete));
            ps.setInt(4, idCita);
            rs = ps.executeQuery();
            rs.next();
            boolean duplicado = rs.getInt(1) > 0;
            rs.close(); ps.close();

            if (duplicado) {
                mensaje = "error:Esa fecha y hora ya están ocupadas para ese veterinario.";
            } else {
                ps = con.prepareStatement(
                    "UPDATE citas SET fecha = ?, hora = ?, id_vete = ?, id_mascota = ? WHERE id_citas = ? AND id_tutor = ?"
                );
                ps.setString(1, nuevaFecha);
                ps.setString(2, nuevaHora);
                ps.setInt(3, Integer.parseInt(nuevoIdVete));
                ps.setInt(4, Integer.parseInt(nuevoIdMascota));
                ps.setInt(5, idCita);
                ps.setInt(6, idTutor);
                ps.executeUpdate();
                ps.close(); con.close();
                response.sendRedirect("listarCitas.jsp");
                return;
            }

            fechaActual     = nuevaFecha;
            horaActual      = nuevaHora;
            idVeteActual    = Integer.parseInt(nuevoIdVete);
            idMascotaActual = Integer.parseInt(nuevoIdMascota);
        }
    }
%>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <title>Petify – Editar Cita</title>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="../style.css"/>
</head>
<body class="dashboard">

  <jsp:include page="/nav.jsp"/>

  <div class="main-content">
    <a href="listarCitas.jsp" class="btn-back">← Volver</a>
    <h2 class="page__title">Editar Cita</h2>

    <% if (mensaje != null && mensaje.startsWith("error:")) { %>
      <p class="error-msg" style="margin-bottom:1rem; padding-left:0;">
        <%= mensaje.substring(6) %>
      </p>
    <% } %>

    <div class="card" style="padding: 2rem;">
      <form method="post" action="editarCita.jsp?id=<%= idCita %>">

        <div class="form-group">
          <label for="id_vete">Veterinario</label>
          <div class="input-wrap">
            <select id="id_vete" name="id_vete" class="select-input">
              <%
                ps = con.prepareStatement("SELECT id_vete, nom_vete, especialidad FROM veterinario");
                rs = ps.executeQuery();
                while (rs.next()) {
                    int id = rs.getInt("id_vete");
              %>
              <option value="<%= id %>" <%= id == idVeteActual ? "selected" : "" %>>
                <%= esc(rs.getString("nom_vete")) %> — <%= esc(rs.getString("especialidad")) %>
              </option>
              <% } rs.close(); ps.close(); %>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label for="id_mascota">Mascota</label>
          <div class="input-wrap">
            <select id="id_mascota" name="id_mascota" class="select-input">
              <%
                ps = con.prepareStatement("SELECT id_mascota, nombre FROM mascota WHERE id_tutor = ?");
                ps.setInt(1, idTutor);
                rs = ps.executeQuery();
                while (rs.next()) {
                    int id = rs.getInt("id_mascota");
              %>
              <option value="<%= id %>" <%= id == idMascotaActual ? "selected" : "" %>>
                <%= esc(rs.getString("nombre")) %>
              </option>
              <% } rs.close(); ps.close(); %>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label for="fecha">Fecha</label>
          <div class="input-wrap">
            <input type="date" id="fecha" name="fecha" value="<%= fechaActual %>"
                   style="padding-left: 18px;"/>
          </div>
        </div>

        <div class="form-group">
          <label for="hora">Hora</label>
          <div class="input-wrap">
            <select id="hora" name="hora" class="select-input">
              <% String[] horas = {"09:00","10:00","11:00","12:00","13:00","16:00","17:00","18:00"};
                 for (String h : horas) { %>
              <option value="<%= h %>" <%= h.equals(horaActual.substring(0,5)) ? "selected" : "" %>>
                <%= h %>
              </option>
              <% } %>
            </select>
          </div>
        </div>

        <button type="submit" class="btn-acceso">Guardar cambios</button>
      </form>
    </div>
  </div>

  <% if (con != null && !con.isClosed()) con.close(); %>
</body>
</html>