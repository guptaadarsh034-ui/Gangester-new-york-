package com.nexusdev.gny;
import android.os.Bundle;
import com.badlogic.gdx.backends.android.AndroidApplication;
import com.badlogic.gdx.backends.android.AndroidApplicationConfiguration;
public class AndroidLauncher extends AndroidApplication {
 @Override public void onCreate(Bundle state) {
  super.onCreate(state);
  AndroidApplicationConfiguration c=new AndroidApplicationConfiguration();
  c.useImmersiveMode=true; c.useAccelerometer=false; c.useCompass=false; c.useGL30=true;
  initialize(new GangsterGame(),c);
 }
}