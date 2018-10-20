<<< "Jim Freeman" >>>;
<<< "Assignment 1" >>>;

// "distance" between our notes
1.059463094359 => float halfStep;

//save our running time
30 => float runningTime;

//save our expected end time
now + 30::second => time later;

//initial gain for our tune
0 => float gain;

//duration by which we'll advanec time
.1::ms => dur timeStep;

//save our startTime
now => time startTime;

//report start time
<<< "startTime", startTime / second>>>;

//set min/max gain for our notes
.2 => float minGain;
.5 => float maxGain;

//choose an A as our starting frequency
110 => float startingFreq;

//create all the oscillators we'll use
SinOsc s => dac;
TriOsc t => dac;
SqrOsc sq => dac;
SawOsc sw => dac;

//flag to tell us whether to raise our gain or lower it
1 => int raiseGain;

//this is the value by which we change the gain on our notes
//which changes the tempo of our composition by changing the time it
//takes to cycle between min and max gain
.000323 => float startingGainStep;
startingGainStep => float gainStep;

startingFreq => s.freq;
startingFreq => t.freq;

//init the square osc part of our tick sound network
4700 => sq.freq;
0 => sq.gain;
0 => int sqOn;

//init the saw osc part of our tick sound network
2900 => sw.freq;
0 => sw.gain;
0 => int swOn;

//init bar count
0 => int bar;

//init the number of half steps between our notes/positions
0 => int steps;
0 => int Isteps;
5 => int IVsteps;
7 => int Vsteps;

//init beat count
0 => int beat;

//initial gain ratio between sin and sqr osc (1:gainRatio)
10 => float gainRatio;


//init tick gain
0 => float tickGain;
//initial max tick Gain
.05 => float maxTickGain;

//flag to tell us whether to raise or lower tick gain
1 => int raiseTickGain;
.002 => float startingTickGainStep;
startingGainStep => float tickGainStep;

//set a max gain for our ticks
.09 => float maxTickGainLimit;

//init our "count to X" counters
0 => int tickCount3;
0 => int tickCount4;
0 => int tickCount5;

//let's loop thru some music!
while (now < later) {
    
    //increment "count 3 ticks" counter
    tickCount3++;
    //reset "count 3 ticks" counter if needed
    if (tickCount3 > 3) 1 => tickCount3;
    //increment "count 4 ticks" counter
    tickCount4++;
    //reset "count 4 ticks" counter if needed
    if (tickCount4 > 4) 1 => tickCount4;
    //increment "count 5 ticks" counter
    tickCount5++;
    //reset "count 5 ticks" counter if needed    
    if (tickCount5 > 5) 1 => tickCount5;
 
    
    // if below max gain and haven't hit our max, increase gain by gainstep
    if (gain < maxGain && raiseGain == 1)
    {
        gainStep +=> gain; 
    }
    else //either we've exceeded our max gain, or raiseGain is "true"
    {
        // if we've exceeded max gain and haven't set raiseGain, we need to set it
        if (gain >= maxGain && raiseGain == 1)
        {
            //now the gain will not increase
            0 => raiseGain;
        }
        //while we're still above our min gain, reduce gain
        if (gain > minGain) 
        {
            gainStep -=> gain;
        }
        else //now we're at min gain. nice time to change things?
        {
            //start a tick
             1 => raiseTickGain;
            

            //keep this value from going crazy
            if (maxTickGain > maxTickGainLimit) maxTickGainLimit => maxTickGain;  

            //semi-randomly chosen conditions on which to raise or lower tick gain, which also affects tick duration
            if (tickCount4 + tickCount5 == tickCount3 * 3) .09 +=> maxTickGain; 
            if (tickCount4 == 1) .009 -=> maxTickGain; 
            if (tickCount3 == 2) .01 -=> maxTickGain; 
            if (tickCount3 == 3 && tickCount4 == 3) .07 +=> maxTickGain;  
             
            //increment the beat count
            beat++;
            //don't let beat count get above 12
            if (beat > 12 )
            {
                1 => beat;
                //increment bar count
                bar++;
            }
            
            //if we've gone over 12 beats, start over
            if (beat > 12) 1 => beat;
            
            //on beats 1-4, 7,8 and 11, play our I note
            if (beat <  4 || (beat > 6 && beat < 9) || beat == 11) Isteps => steps;
            //on beats 5, 6 and 10, play our IV note  
            if ((beat > 4 && beat < 7) || beat == 10)  IVsteps => steps;
            //on beats 9 and 19, play our V note
            if (beat == 9 || beat == 12) Vsteps => steps;
               
            //if we've got over 12 "bars" start over
            if (bar > 12) 1 => bar;
            
            //on bars 1-4, 7,8 and 1 play our riff in the I position
            if (bar <  4 || (bar > 6 && bar < 10) || bar == 9) steps + Isteps => steps;
            //on bars 5, 6 and 12, play our riff in the IV position  
            if ((bar > 4 && bar < 7) || bar == 12)  steps + IVsteps => steps;
            //on bars 9 and 11, play our riff in the V position    
            if (bar == 9 || bar == 11) steps + Vsteps => steps;
              
            //reset freq to start freq for our calc
            startingFreq => float freq;
            //calculate the note we want by multiplying the number of half steps from 
            for (1 => int i; i <= steps; i++)
            {
                freq * 1.059463094359 => freq;
            }
            
            //set our frequencies to octaves of the value calculated
            freq * 3 => s.freq;
            freq / 2 => t.freq;
            
            
            //make sure we un-set raiseGain so gain will rise again
            1 => raiseGain;
        }
    }
    
    //on each loop, set our gain to whatever we've calculated
    gain => s.gain;
    //slowly reduce the ratio between the sin and tri oscillators until it gets to 1.5
    if (gainRatio > 1.5) .00005 -=> gainRatio;
    //set tri osc gain to a ratio of the sin gain    
    gain / gainRatio => t.gain;
    

    //ticks work a little like the tune, but they don't try to rise and fall continuously
    //when they hit zero, they stay there until the next tick.
    
    //increase tick gain if we have'nt hit max and are in "raise" mode
    if (tickGain < maxTickGain && raiseTickGain == 1) tickGainStep +=> tickGain;
    else
    {
        //correct the state of raiseTickGain if we've just hit max
        if (tickGain >= maxTickGain && raiseTickGain == 1) 0 => raiseTickGain;
         
        //reduce tick gain to zero, then don't do anything
        if (tickGain > 0) tickGainStep -=> tickGain;
    }
   
    //set the volume for our ticks
    tickGain => sq.gain;
    tickGain / 2  => sw.gain;

    //sdvance one timeStep
    timeStep => now;
}

//report end time
<<< "Done now!", now / second>>>;