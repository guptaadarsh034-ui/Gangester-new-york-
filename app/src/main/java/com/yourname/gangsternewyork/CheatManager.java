package com.yourname.gangsternewyork;

public class CheatManager {

    public boolean speedBoost = false;
    public boolean godMode = false;
    public boolean infiniteRun = false;

    public void toggleSpeedBoost() { speedBoost = !speedBoost; }
    public void toggleGodMode() { godMode = !godMode; }
    public void toggleInfiniteRun() { infiniteRun = !infiniteRun; }

    public float getSpeedMultiplier() {
        return speedBoost ? 2.0f : 1.0f;
    }
}
