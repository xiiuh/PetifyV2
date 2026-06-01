<%@ page contentType="text/html;charset=UTF-8" %>
<%
    String usuario = request.getParameter("j_username");
    String password = request.getParameter("j_password");

    try {
        request.login(usuario, password);

        String urlOriginal = (String) session.getAttribute("javax.servlet.forward.request_uri");
        
        if (urlOriginal != null) {
            session.removeAttribute("javax.servlet.forward.request_uri");
            response.sendRedirect(urlOriginal);
        } else if (request.isUserInRole("tutor")) {
            response.sendRedirect("tutor/dashboard.jsp");
        } else if (request.isUserInRole("veterinario")) {
            response.sendRedirect("veterinario/agenda.jsp");
        } else {
            response.sendRedirect("login.jsp?error=1");
        }
    } catch (Exception e) {
        response.sendRedirect("login.jsp?error=1");
    }
%>