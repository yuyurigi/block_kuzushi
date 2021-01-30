import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.*;

import java.util.Calendar;

int gseq; //ゲームの流れ管理
int px = 200; //パドルの最初のx位置
int py = 750; //パドルのy位置
int pw = 150; //パドルの横幅
int ph = 20; //パドルの高さ
float bx; //ball 座標
float by;
float spdx; //ball 速度
float spdy;
int br = 21; //ball　半径
int phit = 0; //0:no 1:自機とヒット
int blockNum = 340;
int[] blf = new int[blockNum]; //0:ブロック非表示 1:表示
int[] blx = new int[blockNum]; //ブロックのx位置
int[] bly = new int[blockNum]; //ブロックのy位置
int blw = 40; //ブロックの幅と高さ
int blh = 40;
float lastx; //移動前の位置
float lasty;
int bexist = 0; // 0:no 1:ブロックが存在する
int mcnt; //メッセージ用カウンタ
int ccnt; //クリア画面に変わるまでの時間用カウンタ
int life; //リトライ回数 残機
boolean muteki = false; //無敵時間

PFont font;
PImage frontImg0, backImg, frontImg;
Minim minim;
AudioPlayer[] music = new AudioPlayer[3]; //音楽
AudioSample[] sound = new AudioSample[5]; //効果音
boolean sb = true; //音楽のありなし（true：あり、false：なし）

void setup() {
  size(800, 800);
  noStroke();
  colorMode(HSB, 100, 100, 100, 100);
  font = createFont("pkmn_s.ttf", 40);
  textFont(font);
  frontImg0 = loadImage("front.png");
  backImg = loadImage("back.png");
  minim = new Minim( this );
  music[0] = minim.loadFile("op.mp3"); //タイトル画面のときに流れる音楽
  music[1] = minim.loadFile("ed.mp3"); //ゲームクリア時の音楽
  music[2] = minim.loadFile("go.mp3"); //ゲームオーバー時の音楽
  sound[0] = minim.loadSample("kettei.wav"); //マウスクリック音
  sound[1] = minim.loadSample("hit.wav"); //ブロックにあたったときの音
  sound[2] = minim.loadSample("wall.wav"); //ボールが壁にあたったときの音
  sound[3] = minim.loadSample("paddle.wav"); //ボールがパドルにあたったときの音
  sound[4] = minim.loadSample("miss.wav"); //ボールが下に落ちたときの音
  gameInit(); //ゲーム関連の初期化
}

void draw() {
  background(backImg);
  if ( gseq == 0 ) {
    gameTitle();
  } else if ( gseq == 1 ) {
    gamePlay();
  } else if ( gseq == 2) {
    retry();
  } else if ( gseq == 3) {
    gameClear();
  } else if ( gseq == 4) {
    gameOver();
  }

  if (sb) {
    if (gseq == 0) {
      music[0].play(); //音楽を再生
    } else {
      music[0].pause();  //サウンドデータを止める
      music[0].rewind(); //再生開始位置を先頭に移動させる
    }

    if (gseq == 3) {
      music[1].play();
    } else {
      music[1].pause(); 
      music[1].rewind();
    }

    if (gseq == 4) {
      music[2].play();
    } else {
      music[2].pause(); 
      music[2].rewind();
    }
  }
}

void gameInit() { //ゲーム初期化
  gseq = 0;
  spdx = 5;
  spdy = 5;
  phit = 0;
  bexist = 0;
  mcnt = 0;
  ccnt = 0;
  life = 6;
  blockInit();
}

void blockInit() {
  frontImg = frontImg0.copy();
  //画像が透明のところはブロックが表示されない
  for (int i = 0; i < blockNum; i++) {
    blf[i] = 0; // 0:ブロック非表示 1:表示
    blx[i] = (i%20) * (blw);
    bly[i] = (i/20) * (blh);
    for (int x = blx[i]; x < blx[i]+blw; x++) {
      for (int y = bly[i]; y < bly[i]+blh; y++) {
        int pos = (y * frontImg.width) + x;
        color c = frontImg.pixels[pos];
        if (alpha(c) == 100) { // 透明でないところが１箇所あればforループから抜ける
          blf[i] = 1; 
          break;
        }
        if (blf[i] == 1) {
          break;
        }
      }
    }
  }
}

void gameTitle() {//ゲームタイトル画面
  bx = px+pw/2;
  by = py-ph/2-3;
  playerMove();
  playerDisp();
  blockDisp();
  drawFrontImg();
  ballDisp();
  scoreDisp();
  mcnt++;
  if ( (mcnt%60) < 40 ) {
    textSize(40);
    fill(20, 100, 100);
    textAlign(CENTER);
    text("CLICK TO START", width/2, 360*1.6);
  }
}

void gamePlay() { //ゲーム中の画面
  playerMove();
  playerDisp();
  blockDisp();
  drawFrontImg();
  ballMove();
  ballDisp();
  scoreDisp();
}

void retry() {
  bx = px+pw/2;
  by = py-ph/2-3;
  playerMove();
  playerDisp();
  blockDisp();
  drawFrontImg();
  ballDisp();
  scoreDisp();
}

void gameOver() { //ゲームオーバー画面
  playerDisp();
  blockDisp();
  drawFrontImg();
  scoreDisp();
  textSize(50);
  fill(1, 100, 100);
  textAlign(CENTER);
  text("GAME OVER", width/2, 480);
  mcnt++;
  if ( (mcnt%60) < 40 ) {
    textSize(20);
    fill(20, 100, 100);
    text("CLICK TO RETRY!", width/2, 576);
  }
}

void gameClear() { //ゲームクリア画面
  playerDisp();
  blockDisp();
  scoreDisp();
  textSize(50);
  fill(52, 51, 100);
  textAlign(CENTER);
  text("GAME CLEAR", width/2, 480);
  mcnt++;
  if ( (mcnt%60) < 40 ) {
    textSize(20);
    fill(20, 100, 100);
    text("PLAY AGAIN?", width/2, 576);
  }
}

void playerDisp() { //パドル
  if (phit == 1) {
    fill(52, 51, 100);
    rect(px, py, pw, ph);
  }
  stroke(3, 100, 100);
  line(px+pw/2, py, px+pw/2, py+ph);
  strokeWeight(3);
  stroke(0); 
  line(px, py, px+pw, py);
  line(px, py+ph, px+pw, py+ph);

  drawDotArc(px+pw, py, 0);
  drawDotArc(px, py, 1);
  noStroke();
}

void drawDotArc(int x, int y, int a) {
  if (a == 0) { //右半分
    stroke(3, 100, 100);
    fill(3, 100, 100);
    rect(x, y, 6, ph);
    rect(x+6, y+3, 3, ph-3*2);
    rect(x+9, y+6, 3, ph-6*2);
    //輪郭
    stroke(0);
    line(x, y, x+6, y);
    line(x+9, y+3, x+9, y+3);
    line(x+12, y+6, x+12, y+15);
    line(x+9, y+ph-3, x+9, y+ph-3);
    line(x, y+ph, x+6, y+ph);
  } else { //左半分
    stroke(3, 100, 100);
    fill(3, 100, 100);
    rect(x-6, y, 6, ph);
    rect(x-9, y+3, 3, ph-3*2);
    rect(x-12, y+6, 3, ph-6*2);
    //輪郭
    stroke(0);
    line(x-6, y, x, y);
    line(x-9, y+3, x-9, y+3);
    line(x-12, y+6, x-12, y+15);
    line(x-9, y+ph-3, x-9, y+ph-3);
    line(x, y+ph, x-6, y+ph);
  }
}

void playerMove() {
  px = mouseX-pw/2;
  if ( (px+pw+ph/2) > width) { 
    px = width - pw-ph/2-3;
  } else if ((px-ph/2) < 0) {
    px = ph/2+3;
  }
}

void ballDisp() { //ボール
  rectMode(CENTER);
  strokeWeight(3);

  if (muteki) { //無敵時間カラー（赤）
    stroke(3, 100, 100);
    fill(3, 100, 100);
  } else { //デフォルトカラー（緑）
    stroke(20, 100, 100);
    fill(20, 100, 100);
  }

  rect(bx, by, br-6, br-6);
  rectMode(CORNER);
  rect(bx-1.5*3, by-3.5*3, 3*3, 1*3);
  rect(bx-3.5*3, by-1.5*3, 1*3, 3*3);
  rect(bx+2.5*3, by-1.5*3, 1*3, 3*3);
  rect(bx-1.5*3, by+2.5*3, 3*3, 1*3);

  //輪郭
  stroke(0);
  line(bx-1.5*3, by-3.5*3, bx+1.5*3, by-3.5*3); //上
  line(bx+2.5*3, by-2.5*3, bx+2.5*3, by-2.5*3); //右上
  line(bx+3.5*3, by-1.5*3, bx+3.5*3, by+1.5*3); //右
  line(bx+2.5*3, by+2.5*3, bx+2.5*3, by+2.5*3); //右下
  line(bx-1.5*3, by+3.5*3, bx+1.5*3, by+3.5*3); //下
  line(bx-2.5*3, by+2.5*3, bx-2.5*3, by+2.5*3); //左下
  line(bx-3.5*3, by-1.5*3, bx-3.5*3, by+1.5*3); //左
  line(bx-2.5*3, by-2.5*3, bx-2.5*3, by-2.5*3); //左上
}

void ballMove() {
  lastx = bx; //移動する前の位置を退避
  lasty = by;
  bx += spdx;
  by -= spdy;
  if ( by+br > height ) { //画面下へ出たとき
    if (sb) sound[4].trigger();
    //spdy = -spdy;       //跳ね返す（仮）
    if ( bexist != 0) { //ライフを減らす（ブロックが０でないとき）
      life -= 1;
    }
    if (life == 0) {
      //ライフが0になった場合、ゲームオーバー画面へ
      gseq = 4;
    } else {
      //リトライ画面へ
      gseq = 2;
    }
  } 
  if ( by-br/2 < 0 ) {         //画面上へ出たとき
    spdy = spdy * -1;
    if (sb) sound[2].trigger();
  }
  //画面左右へ出たとき
  if ( (bx-br/2 < 0) || (bx+br/2 > width) ) {
    spdx = spdx * -1;
    if (sb) sound[2].trigger();
  }

  // 自機との当たり判定
  if ( (phit == 0) && (px < bx+br/2) && (px + pw > bx-br/2)
    && (py < by+br/2) && (py+ph > by-br/2) ) {
    if (sb) sound[3].trigger();

    //１０ぶんの１の確率で無敵時間
    if (muteki == true) {
      muteki = false;
    }
    int m = (int)random(10);
    if (m == 0) {
      muteki = true;
    }

    spdy = -spdy;
    //ボールのx位置に角度をつける
    //パッドのはしに当たると鋭角に
    boolean mp = true;
    if (spdx<0) {
      mp = false;
    }
    float dis = bx - (px+pw/2);
    float mdis, pdis;
    if (dis <= 0) {
      dis = constrain(dis, -(br/2+pw/2), 0);
      mdis = map(dis, -(br/2+pw/2), 0, (br/2+pw/2)/8, 4);
      spdx = mdis;
    }
    if (0 <= dis) {
      dis = constrain(dis, 0, br/2+pw/2);
      pdis = dis;
      pdis = map(dis, 0, br/2+pw/2, 4, (br/2+pw/2)/8);
      spdx = pdis;
    }
    if (mp == false) {
      spdx *= -1;
    }

    phit = 1; //0:no 1:自機とヒット
  }
  //自機よりも上にいるとき
  if ( by < py - 30) {
    phit = 0;
  }
}

void blockDisp() {
  bexist = 0;
  for (int i = 0; i <blockNum; i++) {
    if (blf[i] == 1) { // 0:ブロック非表示 1:表示
      /* //ブロック表示
       fill(0, 30, 100, 80); //色、彩度、明度
       stroke(0);
       rect(blx[i], bly[i], blw, blh);
       */
      blockHitCheck(i, blx[i], bly[i]);
      bexist = 1; // 1:ブロックが存在する
    }
  }
  if ( bexist == 0) {
    ccnt++;
    if (ccnt > 30) { //30フレームたってから
      //ブロックがなくなったらクリア画面
      gseq = 3;
    }
  }
}

void drawFrontImg() {
  //全面画像を表示
  //ボールで消した箇所は透明になる
  frontImg.loadPixels();
  for (int i = 0; i <blockNum; i++) {
    if (blf[i] == 0) {
      for (int x = blx[i]; x< blx[i]+blw; x++) {
        for (int y = bly[i]; y < bly[i]+blh; y++) {
          frontImg.pixels[y*frontImg.width + x] = color(0, 0);
        }
      }
    }
  }
  frontImg.updatePixels();
  image(frontImg, 0, 0);
}

void  blockHitCheck(int ii, int xx, int yy) { //玉とブロックの当たり判定
  if ( !((xx < bx+br/2) && (xx + blw > bx-br/2)
    && (yy < by+br/2) && (yy+blh > by-br/2)) ) {
    return; //ブロックと接触してないので戻る
  }
  if (sb) sound[1].trigger();
  blf[ii] = 0; //0:ブロックなし

  if (!muteki) {
    //どの方向から接触したのかチェック
    if ( (xx <= lastx) && (xx +blw >= lastx) ) {
      // ブロックの幅の中にいた
      spdy = -spdy; //上下の向きを変更
      return;
    }
    if ( (yy <= lasty) && (yy+blh >= lasty) ) {
      // ブロックの高さの中にいた
      spdx = -spdx; //左右の向きを変更
      return;
    }
  }
}

void scoreDisp() {
  textSize(24);
  fill(0, 0, 0);
  textAlign(LEFT);
  String t = "ΑΒΛΛΛΛΛΛΜ";
  switch(life) {
  case 0:
    t = "ΑΒΔΓΓΓΓΓΜ";
    break;
  case 1:
    t = "ΑΒΛΔΓΓΓΓΜ";
    break;
  case 2:
    t = "ΑΒΛΛΔΓΓΓΜ";
    break;
  case 3:
    t = "ΑΒΛΛΛΔΓΓΜ";
    break;
  case 4:
    t = "ΑΒΛΛΛΛΔΓΜ";
    break;
  case 5:
    t = "ΑΒΛΛΛΛΛΔΜ";
    break;
  case 6:
    t = "ΑΒΛΛΛΛΛΛΜ";
    break;
  }
  text(t, 10, 25);
  text(life + "0/", 60, 55);
  text("60", 155, 55);
}

void stop()
{
  if (sb) {
    for (int i = 0; i < music.length; i++) {
      music[i].close();
    }
    minim.stop();
    super.stop();
  }
}

void mousePressed() {
  if ( gseq == 0 || gseq == 2) {
    if (gseq == 0 &&  sb) {
      sound[0].trigger();
    }
    gseq = 1; //プレイ開始
  }
  if ( gseq == 3 || gseq == 4) { // ゲームクリア/ゲームオーバー中
    //sound[0].trigger();
    gameInit();
    return;
  }
}

void keyPressed() {
  if (key == 's' || key == 'S')saveFrame(timestamp()+"_####.png");
}


String timestamp() {
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}
