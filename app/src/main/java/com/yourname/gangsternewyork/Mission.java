package com.yourname.gangsternewyork;

public class Mission {
    public String title;
    public String description;
    public int targetCol, targetRow;
    public boolean completed = false;
    public boolean active = false;

    public Mission(String title, String description, int targetCol, int targetRow) {
        this.title = title;
        this.description = description;
        this.targetCol = targetCol;
        this.targetRow = targetRow;
    }
}
