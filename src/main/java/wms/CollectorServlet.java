package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet({"/collectors", "/collectors/edit"})
public class CollectorServlet extends HttpServlet {

    private final CollectorDAO dao = new CollectorDAO();
    private final ZoneDAO zoneDao = new ZoneDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("zones", zoneDao.findAll());
            if (req.getServletPath().endsWith("/edit")) {
                req.setAttribute("col", dao.findById(Integer.parseInt(req.getParameter("id"))));
                req.getRequestDispatcher("/collector-edit.jsp").forward(req, res);
                return;
            }
            req.setAttribute("search", req.getParameter("q"));
            req.setAttribute("cols", dao.findAll(req.getParameter("q")));
            req.getRequestDispatcher("/collectors.jsp").forward(req, res);
        } catch (Exception e) { throw new ServletException(e); }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        try {
            if ("add".equals(action)) {
                dao.insert(req.getParameter("name"), req.getParameter("phone"),
                           req.getParameter("shift"),
                           Integer.parseInt(req.getParameter("zone_id")));
                req.getSession().setAttribute("flash", "Collector added");
            } else if ("update".equals(action)) {
                dao.update(Integer.parseInt(req.getParameter("collector_id")),
                           req.getParameter("name"), req.getParameter("phone"),
                           req.getParameter("shift"),
                           Integer.parseInt(req.getParameter("zone_id")));
                req.getSession().setAttribute("flash", "Collector updated");
            } else if ("delete".equals(action)) {
                dao.delete(Integer.parseInt(req.getParameter("collector_id")));
                req.getSession().setAttribute("flash", "Collector deleted");
            }
        } catch (Exception e) {
            req.getSession().setAttribute("flash", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/collectors");
    }
}