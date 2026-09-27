package com.yourname.gangsternewyork;

import java.util.ArrayList;
import java.util.List;

public class MissionManager {

    private List<Mission> missions = new ArrayList<>();
    private Mission currentMission;

    public MissionManager() {
        missions.add(new Mission("Delivery Run", "Reach the docks to pick up a package.", 2, 1));
        missions.add(new Mission("Park Meetup", "Meet your contact in Central Park.", 6, 8));
        missions.add(new Mission("Financial Heist", "Get to the Financial District fast.", 2, 3));
    }

    public void startNextMission() {
        for (Mission m : missions) {
            if (!m.completed) {
                currentMission = m;
                currentMission.active = true;
                return;
            }
        }
        currentMission = null;
    }

    public Mission getCurrentMission() {
        return currentMission;
    }

    public void checkCompletion(int playerCol, int playerRow) {
        if (currentMission != null
                && playerCol == currentMission.targetCol
                && playerRow == currentMission.targetRow) {
            currentMission.completed = true;
            currentMission.active = false;
            currentMission = null;
        }
    }

    public boolean hasAvailableMission() {
        for (Mission m : missions) {
            if (!m.completed) return true;
        }
        return false;
    }

    public boolean allMissionsComplete() {
        return !hasAvailableMission();
    }
}
