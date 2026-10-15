package wms;

public class Pickup {
    private int id;
    private int binId;
    private String binLocation;
    private int collectorId;
    private String collectorName;
    private String pickupDate;
    private double weight;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public int getBinId() { return binId; }
    public void setBinId(int binId) { this.binId = binId; }
    public String getBinLocation() { return binLocation; }
    public void setBinLocation(String s) { this.binLocation = s; }
    public int getCollectorId() { return collectorId; }
    public void setCollectorId(int c) { this.collectorId = c; }
    public String getCollectorName() { return collectorName; }
    public void setCollectorName(String s) { this.collectorName = s; }
    public String getPickupDate() { return pickupDate; }
    public void setPickupDate(String d) { this.pickupDate = d; }
    public double getWeight() { return weight; }
    public void setWeight(double w) { this.weight = w; }
}