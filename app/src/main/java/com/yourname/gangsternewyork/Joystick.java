package com.yourname.gangsternewyork;

import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;

public class Joystick {

    private float baseX, baseY;
    private float stickX, stickY;
    private float radius = 80f;
    private int pointerId = -1;

    private float moveX = 0f, moveY = 0f;

    public Joystick(float baseX, float baseY) {
        this.baseX = baseX;
        this.baseY = baseY;
        this.stickX = baseX;
        this.stickY = baseY;
    }

    public boolean isTouchOnBase(float x, float y) {
        float dx = x - baseX;
        float dy = y - baseY;
        return Math.sqrt(dx * dx + dy * dy) <= radius * 1.5f;
    }

    public void setPointerId(int id) { pointerId = id; }
    public int getPointerId() { return pointerId; }

    public void updateStick(float x, float y) {
        float dx = x - baseX;
        float dy = y - baseY;
        double distance = Math.sqrt(dx * dx + dy * dy);

        if (distance > radius) {
            dx = (float) (dx / distance * radius);
            dy = (float) (dy / distance * radius);
        }

        stickX = baseX + dx;
        stickY = baseY + dy;

        moveX = dx / radius;
        moveY = dy / radius;
    }

    public void reset() {
        stickX = baseX;
        stickY = baseY;
        moveX = 0f;
        moveY = 0f;
        pointerId = -1;
    }

    public float getMoveX() { return moveX; }
    public float getMoveY() { return moveY; }

    public void draw(Canvas canvas) {
        Paint basePaint = new Paint();
        basePaint.setColor(Color.argb(120, 200, 200, 200));
        canvas.drawCircle(baseX, baseY, radius, basePaint);

        Paint stickPaint = new Paint();
        stickPaint.setColor(Color.argb(200, 255, 255, 255));
        canvas.drawCircle(stickX, stickY, radius / 2.5f, stickPaint);
    }
}
