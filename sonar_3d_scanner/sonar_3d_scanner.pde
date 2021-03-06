import java.util.*;
import processing.serial.*;

/*
 * CNU Bottom-up project (2020)
 * Sonar 3D scanner measurement visualization code 
 * made by team Umpa-Umpa (hotmosit, hj-k66) 
 */



// actual height rises 0.07cm per 360 degree turn
// one step table turn is 1.8 degree (radian(1.8))
// closest distance between table and sensor is near 7 cm 


Serial port;

ArrayList<Dots> list = new ArrayList<Dots>();
int t_case = 0;


String val;
float[] serialVal = new float[4];
int serialCount = 0;
float angle = 0;
float distance = 0;
float h = 0;

// scan debug
int count = 0;


final float DISTANCE_CENTER = 10; //distance of sensor~~center

float x = 0;
float y = 0;
float z = 0;

// buttons
Button start;
Button pause;
Button view;
Button exit;

// adjust confirmation boolean value
boolean adjust = false;

//-----text file output code added--------
PrintWriter output;
//----------------------------------------

boolean isValued; // check if all value is imported from arduino

void setup() {
  size(1000, 1000, P3D);
  background(0);
  printArray(Serial.list());
  port = new Serial(this, Serial.list()[0], 9600);

  start = new Button("start scanning");
  pause = new Button("pause scanning");
  view  = new Button("view object");
  exit = new Button("exit");

  //--------text value---------------
  output = createWriter("pointData.txt");
  //---------------------------------
}


void draw() {
  // debug
  // println(t_case);

  translate(500, 800);
  background(0);
  stroke(255);
  fill(0, 255, 0);

  // draw line for center coordinate plane
  line(0, -800, 0, 0, 200, 0);
  line(-500, 0, 0, 500, 0, 0);
  line(0, 0, 500, 0, 0, -500);
  textSize(20);
  text("(0, 800, 0)", 0, -780, 0);
  text("(0, -200, 0)", 0, 180, 0);
  text("(500, 0, 0)", 390, 15, 0);
  text("(-500, 0, 0)", -500, 15, 0);

  //--------------
  isValued = false;
  //--------------




  if (t_case < 4) {
    // t_case == 4 is for outlook of the scan 
    // buttons will disapear when t_case = 4
    start.createButton(-480, -750);
    pause.createButton(-480, -700);
    view.createButton(-480, -650);
    exit.createButton(-480, -600);

    textSize(20);
    text("current height : " + h, 280, -780);
  }

  if (exit.click()) {
    // program exit button
    // send arduino state value as 'e'
    // arduino will stop it's function because their is no codes for 'e' state 
    port.write('e');
    exit();
  }


  if (t_case == 0) {
    // adjusting sonar scanning case

    line(-200, -400, 0, 200, -400, 0);
    line(-200, -300, 0, 200, -300, 0);
    line(-200, -400, 0, -200, -300, 0);
    line(200, -400, 0, 200, -300, 0);
    textSize(30);
    text("          ADJUSTING... \n"
      + "PLEASE EMPTY THE PLATE", -190, -360);



    if (port.available() > 0) {

      val = port.readStringUntil('\n');

      if (serialCount < 1 && val != null) {

        int t = 0;
        try {
          t = Integer.parseInt(val.substring(0, 1) + "");
        } 
        catch(NumberFormatException e) {
        }


        if ( t == 1) {
          t_case = 1;
        }
      }
    }
  }

  if ( t_case == 1) {
    /*
     * case 1 codes
     * this code is for button click code  
     */
    if (start.click()) {
      t_case = 2;
      port.write('2');
    }

    if (list.size() >0) {
      for (int i = 0; i < list.size(); i++) {

        list.get(i).draw_dot();
      }

      delay(1);
    }
  }


  if (t_case == 2) {
    /*
     * case 2 codes
     * this code is for to make boxes of measured points.
     *  
     */
    if (port.available() > 0) {    
      // serial communication with arduino
      // three variable will be sended : distance, angle, height

      val = port.readStringUntil('\n');

      if (serialCount < 4 && val != null) {

        try {
          serialVal[serialCount] = Float.parseFloat(val);
        } 
        catch(NumberFormatException e) {
          val = val.substring(1);
          serialVal[serialCount] = Float.parseFloat(val);
        }
        serialCount++;
      }

      if (serialCount == 4) {
        distance = serialVal[0];
        angle =serialVal[1];
        h = serialVal[2];

        println("filtered distance : " + distance + " angle : " + angle + " height : " + h
          + " distance : " + serialVal[3]);


        serialCount = 0;

        //-------------------
        isValued = true;
        //-------------------

        count++;
      }


      float dist =(DISTANCE_CENTER - distance) * 50;

      /***** scan test code******/
      //--------------------------
      /*
      if (count == 250) {
       t_case = 3;
       }
       //---------------------------
       */
      if ((int)h == 1000 ) { 
        //when there is nothing to scan or either scan is finished
        //end condition
        // arduino will send info as angle = 0, distance = 0, height = 1000
        t_case = 3;
      }

      if ( dist > 0) {

        x = dist*cos(radians(angle));
        y = h * -50;
        z= dist*sin(radians(angle));

        //-------text creating(x,y,z) code------------
        // print point xyz value as x y z 
        // x value = dist * sin(radians(angle), y value = dist * sin(radians(angle)), z = h(=height)
        if (isValued && count >= 1) {
          output.println((dist*sin(radians(angle))) + " " + (dist * cos(radians(angle))) 
            + " " + h );
        
          list.add(new Dots(x, y, z));
        }        
      }
    }


    for (int i = 0; i < list.size(); i++) {
      list.get(i).draw_dot();
    }

    delay(1);

    if (pause.click()) {
      t_case = 1;
      port.write('1');
    }
  }

  if (t_case == 3) {
    /*
     * case 3 codes
     * case 3 activates when scan is finished
     */

    //------text create code--------
    textCreate();
    //-----------------------------

    line(-200, -400, 0, 200, -400, 0);
    line(-200, -300, 0, 200, -300, 0);
    line(-200, -400, 0, -200, -300, 0);
    line(200, -400, 0, 200, -300, 0);
    textSize(50);
    text("SCAN FINISHED", -186, -330);

    port.write('1');

    for (int i = 0; i < list.size(); i++) {
      list.get(i).draw_dot();
    }

    if (view.click()) {
      t_case = 4;
    }
  }

  if (t_case == 4) {
    /*
     * case 4 codes
     * case 4 activates when user want to view scanned object
     * activates when "view object" button is operated
     */

    for (int i = 0; i < list.size(); i++) {
      list.get(i).draw_dot();
    }

    camera(mouseX*2, 0, mouseY*2, 500, 500, 0, 100, 100, 100 );
  }
}

void textCreate() {
  output.flush();
  output.close();
}
