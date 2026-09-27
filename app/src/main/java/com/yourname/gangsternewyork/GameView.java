package com.yourname.gangsternewyork;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

public class GameView extends SurfaceView implements Runnable {

    private Thread gameThread;
    private volatile boolean running = false;
    private SurfaceHolder holder;

    private int playerX = 80, playerY = 80;
    private int playerSpeed = 4;

    private TileMap map = new TileMap();
    private MissionManager missionManager = new MissionManager();
    private Phone phone = new Phone();
    private CheatManager cheatManager = new CheatManager();
    private Joystick joystick;

    public GameView(Context context) {
        super(context);
        holder = getHolder();
        joystick = new Joystick(150, 800);
    }

    @Override
    public void run() {
        while (running) {
            if (!holder.getSurface().isValid()) continue;

            update();
            render();

            try {
                Thread.sleep(16);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    private void update() {
        if (phone.isOpen()) return;

        float effectiveSpeed = playerSpeed * cheatManager.getSpeedMultiplier();
        int newX = playerX + Math.round(joystick.getMoveX() * effectiveSpeed);
        int newY = playerY + Math.round(joystick.getMoveY() * effectiveSpeed);

        int col = newX / TileMap.TILE_SIZE;
        int row = newY / TileMap.TILE_SIZE;

        if (!map.isSolid(col, row)) {
            playerX = newX;
            playerY = newY;
        }

        missionManager.checkCompletion(playerX / TileMap.TILE_SIZE, playerY / TileMap.TILE_SIZE);
    }

    private void render() {
        Canvas canvas = holder.lockCanvas();
        if (canvas == null) return;

        drawMap(canvas);

        Paint playerPaint = new Paint();
        playerPaint.setColor(Color.RED);
        canvas.drawRect(new Rect(playerX, playerY, playerX + 32, playerY + 32), playerPaint);

        joystick.draw(canvas);
        phone.drawIcon(canvas);
        phone.drawOverlay(canvas, missionManager, cheatManager);

        holder.unlockCanvasAndPost(canvas);
    }

    private void drawMap(Canvas canvas) {
        canvas.drawColor(Color.BLACK);
        Paint paint = new Paint();
        for (int row = 0; row < map.getHeightInTiles(); row++) {
            for (int col = 0; col < map.getWidthInTiles(); col++) {
                int tile = map.getTile(col, row);
                switch (tile) {
                    case TileMap.TILE_ROAD: paint.setColor(Color.DKGRAY); break;
                    case TileMap.TILE_BUILDING: paint.setColor(Color.rgb(90, 90, 100)); break;
                    case TileMap.TILE_PARK: paint.setColor(Color.rgb(60, 140, 60)); break;
                    case TileMap.TILE_WATER: paint.setColor(Color.rgb(40, 90, 160)); break;
                    case TileMap.TILE_SIDEWALK: paint.setColor(Color.LTGRAY); break;
                }
                int x = col * TileMap.TILE_SIZE;
                int y = row * TileMap.TILE_SIZE;
                canvas.drawRect(x, y, x + TileMap.TILE_SIZE, y + TileMap.TILE_SIZE, paint);
            }
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int action = event.getActionMasked();
        int pointerIndex = event.getActionIndex();
        int pointerId = event.getPointerId(pointerIndex);
        float x = event.getX(pointerIndex);
        float y = event.getY(pointerIndex);

        switch (action) {
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_POINTER_DOWN:
                if (phone.isPhoneIconTapped(x, y)) {
                    phone.toggle();
                    return true;
                }
                if (phone.isCallButtonTapped(x, y)) {
                    missionManager.startNextMission();
                    phone.toggle();
                    return true;
                }
                if (phone.isTabButtonTapped(x, y)) {
                    phone.toggleTab();
                    return true;
                }
                if (phone.isSpeedCheatTapped(x, y)) {
                    cheatManager.toggleSpeedBoost();
                    return true;
                }
                if (phone.isGodModeCheatTapped(x, y)) {
                    cheatManager.toggleGodMode();
                    return true;
                }
                if (joystick.getPointerId() == -1 && joystick.isTouchOnBase(x, y)) {
                    joystick.setPointerId(pointerId);
                    joystick.updateStick(x, y);
                }
                return true;

            case MotionEvent.ACTION_MOVE:
                for (int i = 0; i < event.getPointerCount(); i++) {
                    if (event.getPointerId(i) == joystick.getPointerId()) {
                        joystick.updateStick(event.getX(i), event.getY(i));
                    }
                }
                return true;

            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_POINTER_UP:
                if (pointerId == joystick.getPointerId()) {
                    joystick.reset();
                }
                return true;
        }
        return true;
    }

    public void resume() {
        running = true;
        gameThread = new Thread(this);
        gameThread.start();
    }

    public void pause() {
        running = false;
        try {
            gameThread.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
