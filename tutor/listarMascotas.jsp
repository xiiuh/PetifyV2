<%@ page import="java.sql.*, javax.naming.*, javax.sql.*" %>
<%! private static String esc(String s) { if(s==null)return""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#x27;"); } %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
    if (request.getUserPrincipal() == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String correo = request.getUserPrincipal().getName();
    int idTutor = 0;

    Context ctx = new InitialContext();
    DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/petify");
    Connection con = ds.getConnection();

    PreparedStatement psId = con.prepareStatement("SELECT id_tutor FROM tutor WHERE correo = ?");
    psId.setString(1, correo);
    ResultSet rsId = psId.executeQuery();
    if (rsId.next()) idTutor = rsId.getInt("id_tutor");
    rsId.close(); psId.close();

    PreparedStatement ps = con.prepareStatement(
        "SELECT m.id_mascota, m.nombre, m.especie, m.raza, m.edad, m.sexo, m.peso, " +
        "v.nom_vete FROM mascota m LEFT JOIN veterinario v ON m.id_vete = v.id_vete " +
        "WHERE m.id_tutor = ?");
    ps.setInt(1, idTutor);
    ResultSet rs = ps.executeQuery();
%>


<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mis Mascotas – Petify</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
</head>
<body class="dashboard">

    <jsp:include page="/nav.jsp"/>

    <div class="main-content">
        <a href="${pageContext.request.contextPath}/tutor/dashboard.jsp" class="btn-back">← Volver</a>
        <h2 class="page__title">Mis Mascotas</h2>

        <a href="${pageContext.request.contextPath}/tutor/registrarMascota.jsp" class="btn-acceso" style="display:inline-block;width:auto;padding:.6rem 1.4rem;margin:1rem 0;text-decoration:none;">
            Registrar mascota
        </a>

        <% if (!rs.next()) { %>
            <p style="color:var(--muted);">No tienes mascotas registradas aun.</p>
        <% } else { %>
        <table class="tabla">
            <thead>
                <tr>
                    <th>Nombre</th>
                    <th>Especie</th>
                    <th>Raza</th>
                    <th>Edad</th>
                    <th>Sexo</th>
                    <th>Peso</th>
                    <th>Veterinario</th>
                    <th>Acciones</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><%= esc(rs.getString("nombre")) %></td>
                    <td><%= esc(rs.getString("especie")) %></td>
                    <td><%= esc(rs.getString("raza")) %></td>
                    <td><%= esc(rs.getString("edad")) %></td>
                    <td><%= esc(rs.getString("sexo")) %></td>
                    <td><%= rs.getDouble("peso") %> kg</td>
                    <td><%= rs.getString("nom_vete") != null ? esc(rs.getString("nom_vete")) : "Sin asignar" %></td>
                    <td>
                        <a href="${pageContext.request.contextPath}/tutor/editarMascota.jsp?id=<%= rs.getInt("id_mascota") %>" class="btn-edit">Editar</a>
                        <a href="${pageContext.request.contextPath}/tutor/eliminarMascota.jsp?id=<%= rs.getInt("id_mascota") %>" class="btn-del"
                           onclick="return confirm('¿Eliminar esta mascota?')">Eliminar</a>
                    </td>
                </tr>
                <% while (rs.next()) { %>
                <tr>
                    <td><%= esc(rs.getString("nombre")) %></td>
                    <td><%= esc(rs.getString("especie")) %></td>
                    <td><%= esc(rs.getString("raza")) %></td>
                    <td><%= esc(rs.getString("edad")) %></td>
                    <td><%= esc(rs.getString("sexo")) %></td>
                    <td><%= rs.getDouble("peso") %> kg</td>
                    <td><%= rs.getString("nom_vete") != null ? esc(rs.getString("nom_vete")) : "Sin asignar" %></td>
                    <td>
                        <a href="${pageContext.request.contextPath}/tutor/editarMascota.jsp?id=<%= rs.getInt("id_mascota") %>" class="btn-edit">Editar</a>
                        <a href="${pageContext.request.contextPath}/tutor/eliminarMascota.jsp?id=<%= rs.getInt("id_mascota") %>" class="btn-del"
                           onclick="return confirm('¿Eliminar esta mascota?')">Eliminar</a>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
        <% } %>
        <% rs.close(); ps.close(); con.close(); %>
    </div>

</body>
</html>