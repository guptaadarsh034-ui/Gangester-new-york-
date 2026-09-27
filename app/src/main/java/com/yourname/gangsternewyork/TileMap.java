package com.yourname.gangsternewyork;

public class TileMap {

    public static final int TILE_ROAD = 0;
    public static final int TILE_BUILDING = 1;
    public static final int TILE_PARK = 2;
    public static final int TILE_WATER = 3;
    public static final int TILE_SIDEWALK = 4;

    public static final int TILE_SIZE = 40;

    private int[][] grid = {
        {3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
        {3,4,0,0,0,0,0,0,0,0,0,0,0,4,3},
        {3,4,1,1,4,1,1,4,1,1,4,1,1,4,3},
        {3,4,1,1,4,1,1,4,1,1,4,1,1,4,3},
        {3,4,0,0,0,0,0,0,0,0,0,0,0,4,3},
        {3,4,1,1,4,1,1,4,1,1,4,1,1,4,3},
        {3,4,1,1,4,1,1,4,1,1,4,1,1,4,3},
        {3,4,0,0,0,0,0,0,0,0,0,0,0,4,3},
        {3,4,2,2,2,2,2,2,2,2,2,2,2,4,3},
        {3,4,2,2,2,2,2,2,2,2,2,2,2,4,3},
        {3,4,0,0,0,0,0,0,0,0,0,0,0,4,3},
        {3,4,1,1,4,1,1,4,1,1,4,1,1,4,3},
        {3,3,3,3,3,3,3,3,3,3,3,3,3,3,3}
    };

    public int getTile(int col, int row) {
        if (row < 0 || row >= grid.length || col < 0 || col >= grid[0].length) {
            return TILE_BUILDING;
        }
        return grid[row][col];
    }

    public boolean isSolid(int col, int row) {
        int tile = getTile(col, row);
        return tile == TILE_BUILDING || tile == TILE_WATER;
    }

    public int getWidthInTiles() { return grid[0].length; }
    public int getHeightInTiles() { return grid.length; }
}
