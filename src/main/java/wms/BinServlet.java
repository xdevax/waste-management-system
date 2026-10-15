package wms;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet({"/bins", "/bins/edit"})
public class BinServlet extends HttpServlet {

    private final BinDAO dao = new BinDAO();
    private final ZoneDAO zoneDao = new ZoneDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        try {
            req.setAttribute("zones", zoneDao.findAll());

            if (req.getServletPath().endsWith("/edit")) {
                int id = Integer.parseInt(req.getParameter("id"));
                req.setAttribute("bin", dao.findById(id));
                req.getRequestDispatcher("/bin-edit.jsp").forward(req, res);
                return;
            }

            req.setAttribute("search", req.getParameter("q"));
            req.setAttribute("bins", dao.findAll(req.getParameter("q")));
            req.getRequestDispatcher("/bins.jsp").forward(req, res);
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        String flash;
        try {
            if ("add".equals(action)) {
                dao.insert(req.getParameter("location"),
                           Double.parseDouble(req.getParameter("capacity")),
                           req.getParameter("waste_type"),
                           Integer.parseInt(req.getParameter("zone_id")));
                flash = "Bin added successfully";
            } else if ("update".equals(action)) {
                dao.update(Integer.parseInt(req.getParameter("bin_id")),
                           req.getParameter("location"),
                           Double.parseDouble(req.getParameter("capacity")),
                           req.getParameter("waste_type"),
                           Integer.parseInt(req.getParameter("zone_id")));
                flash = "Bin updated successfully";
            } else if ("delete".equals(action)) {
                dao.delete(Integer.parseInt(req.getParameter("bin_id")));
                flash = "Bin deleted";
            } else {
                flash = "Unknown action";
            }
            req.getSession().setAttribute("flash", flash);
        } catch (Exception e) {
            req.getSession().setAttribute("flash", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/bins");
    }
}