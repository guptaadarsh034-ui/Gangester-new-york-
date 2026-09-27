package com.yourname.gangsternewyork;

import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;

public class Phone {

    private boolean open = false;
    private boolean showingCheats = false;

    private Rect phoneIconBounds = new Rect(20, 20, 90, 90);
    private Rect callButtonBounds = new Rect(150, 300, 450, 380);
    private Rect tabButtonBounds = new Rect(150, 400, 450, 450);

    private Rect cheatSpeedBounds = new Rect(150, 200, 450, 250);
    private Rect cheatGodModeBounds = new Rect(150, 260, 450, 310);

    public boolean isOpen() { return open; }

    public void toggle() { open = !open; }

    public boolean isPhoneIconTapped(float x, float y) {
        return phoneIconBounds.contains((int) x, (int) y);
    }

    public boolean isCallButtonTapped(float x, float y) {
        return open && !showingCheats && callButtonBounds.contains((int) x, (int) y);
    }

    public boolean isTabButtonTapped(float x, float y) {
        return open && tabButtonBounds.contains((int) x, (int) y);
    }

    public boolean isSpeedCheatTapped(float x, float y) {
        return open && showingCheats && cheatSpeedBounds.contains((int) x, (int) y);
    }

    public boolean isGodModeCheatTapped(float x, float y) {
        return open && showingCheats && cheatGodModeBounds.contains((int) x, (int) y);
    }

    public void toggleTab() {
        showingCheats = !showingCheats;
    }

    public void drawIcon(Canvas canvas) {
        Paint paint = new Paint();
        paint.setColor(Color.BLACK);
        canvas.drawRect(phoneIconBounds, paint);
        paint.setColor(Color.WHITE);
        paint.setTextSize(20);
        canvas.drawText("PH", phoneIconBounds.left + 15, phoneIconBounds.top + 45, paint);
    }

    public void drawOverlay(Canvas canvas, MissionManager missionManager, CheatManager cheatManager) {
        if (!open) return;

        Paint bg = new Paint();
        bg.setColor(Color.argb(230, 20, 20, 20));
        canvas.drawRect(100, 150, 500, 460, bg);

        Paint text = new Paint();
        text.setColor(Color.WHITE);
        text.setTextSize(26);

        if (showingCheats) {
            canvas.drawText("REDEEM CODES", 130, 190, text);

            Paint speedBtn = new Paint();
            speedBtn.setColor(cheatManager.speedBoost ? Color.rgb(40, 160, 60) : Color.rgb(70, 70, 70));
            canvas.drawRect(cheatSpeedBounds, speedBtn);
            canvas.drawText("SPEED BOOST: " + (cheatManager.speedBoost ? "ON" : "OFF"),
                    cheatSpeedBounds.left + 15, cheatSpeedBounds.top + 32, text);

            Paint godBtn = new Paint();
            godBtn.setColor(cheatManager.godMode ? Color.rgb(40, 160, 60) : Color.rgb(70, 70, 70));
            canvas.drawRect(cheatGodModeBounds, godBtn);
            canvas.drawText("GOD MODE: " + (cheatManager.godMode ? "ON" : "OFF"),
                    cheatGodModeBounds.left + 15, cheatGodModeBounds.top + 32, text);
        } else {
            canvas.drawText("MISSIONS", 130, 190, text);

            Mission current = missionManager.getCurrentMission();
            if (current != null) {
                canvas.drawText("Active: " + current.title, 130, 230, text);
                canvas.drawText(current.description, 130, 265, text);
            } else if (missionManager.allMissionsComplete()) {
                canvas.drawText("All missions complete!", 130, 230, text);
            } else if (missionManager.hasAvailableMission()) {
                canvas.drawText("New mission available!", 130, 230, text);
            }

            Paint callBtn = new Paint();
            callBtn.setColor(Color.rgb(40, 160, 60));
            canvas.drawRect(callButtonBounds, callBtn);
            canvas.drawText("CALL FOR MISSION", callButtonBounds.left + 20, callButtonBounds.top + 50, text);
        }

        Paint tabBtn = new Paint();
        tabBtn.setColor(Color.rgb(60, 60, 160));
        canvas.drawRect(tabButtonBounds, tabBtn);
        canvas.drawText(showingCheats ? "< MISSIONS TAB" : "REDEEM CODES >",
                tabButtonBounds.left + 20, tabButtonBounds.top + 35, text);
    }
}
