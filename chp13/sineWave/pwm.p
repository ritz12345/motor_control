// PRUSS program to output a waveform that is passed from the C program
// Writen by Derek Molloy for the book Exploring BeagleBone modified by Ritaban Chowdhury
// Output is r30.5 (P9_27) and Input is r31.3 (P9_28)

.origin 0               // offset of start of program in PRU memory
.entrypoint START       // program entry point used by the debugger

#define PRU0_R31_VEC_VALID 32
#define EVENTOUT0 3

START:
        // Reading the memory that was set by the C program into registers
        // r2 - Load the sample time delay
        MOV     r0, 0x00000000     //load the memory location
        LBBO    r2, r0, 0, 4       //load the step delay value into r2
        // r5 - Load the number of samples
        MOV     r0, 0x00000004     //load the memory location
        LBBO    r5, r0, 0, 4       //load the number of samples into r5
        MOV     r9, r5
        SUB     r5, r5, 51
        MOV     r6, 0              //r6 is the counter 0 to r5
        MOV     r7, 0x00000008     //load the memory location
SAMPLELOOP:

        MOV    r8, 2000
        MOV    r18,2000
        //Is the counter r6  >= the number of samples r5, if so go back to 0
        //If r6 < r5 then just continue, else set back to 0

        QBLT    CONTINUEONE, r5, r6
        QBLT    CONTINUETWO, r9 , r6
        MOV     r7, 0x00000008
        MOV     r6, 0              //loop all over again
CONTINUEONE:
        SET     r30.t0
        CLR     r30.t1
        // r1 - Read the PWM percent high (0-100)
        ADD     r7, r7, 4
        LBBO    r1, r7, 0, 4       //load the percent value into r1

        //check that the value is between 1 and 99
        QBLT    GREATERTHANZERO, r1, 5
        MOV     r1, 0
GREATERTHANZERO:

        QBGT    LESSTHAN100, r1, 95
        MOV     r1, 100
LESSTHAN100:
        // r3 - The PWM precent that the signal is low (100-r1)
        MOV     r3, 0x64           //load 100 into r3
        SUB     r3, r3, r1         //subtract r1 (high) away.

        // This is for a single sample:
R1HUNDRED:
        MOV     r4, r1             // number of steps high
        QBGE    R1ZERO, r1, 0
        SET     r30.t3             // set the output P9_28 high
SIGNAL_HIGH:
        MOV     r0, r2             // delay how long? load r2 above
DELAY_HIGH:
        SUB     r0, r0, 1          // decrement loop counter
        QBNE    DELAY_HIGH, r0, 0  // repeat until step delay is done
        SUB     r4, r4, 1          // the signal was high for a step
        QBNE    SIGNAL_HIGH, r4, 0 // repeat until signal high % is done
R1ZERO:
        MOV     r4, r3
        QBGE    NEWLOOP, r3,0
        CLR     r30.t3             // set the output P9_28 low

SIGNAL_LOW:
        MOV     r0, r2             // delay how long? load r2 above
DELAY_LOW:
        SUB     r0, r0, 1          // decrement loop counter
        QBNE    DELAY_LOW, r0, 0   // repeat until step delay is done
        SUB     r4, r4, 1          // the signal was low for a step
        QBNE    SIGNAL_LOW, r4, 0  // repeat until signal low % is done

        QBBS    END, r31.t5        // quit if button on P9_27 is pressed
        // Go to the next sample
NEWLOOP:
        SUB     r8,r8,1             // decrement the counter by 1
        QBLT    LESSTHAN100,r8,0
NEXTSAMPLE:
        ADD    r6,r6,1
        QBA    SAMPLELOOP
        MOV     r0, r2             // delay how long? load r2 above
CONTINUETWO:
        SET     r30.t1
        CLR     r30.t0

        ADD     r7, r7, 4
        LBBO    r10, r7, 0, 4       //load the percent value into r1
        QBLT    GREATERTHANZEROTWO, r10, 5
        MOV     r10, 0
GREATERTHANZEROTWO:
        QBGT    LESSTHAN100TWO, r10, 95
        MOV     r10, 100
LESSTHAN100TWO:
        // r3 - The PWM precent that the signal is low (100-r1)
        MOV     r13, 0x64           //load 100 into r3
        SUB     r13, r13, r10         //subtract r1 (high) away.

R1HUNDREDTWO:
        MOV     r14, r10             // number of steps high
        QBGE    R1ZERO_TWO, r10, 0
        SET     r30.t2
                              // set the output P9_28 high
SIGNAL_HIGH_TWO:
        MOV     r15, r2             // delay how long? load r2 above
DELAY_HIGH_TWO:
        SUB     r15, r15, 1          // decrement loop counter
        QBNE    DELAY_HIGH_TWO, r15, 0  // repeat until step delay is done
        SUB     r14, r14, 1          // the signal was high for a step
        QBNE    SIGNAL_HIGH_TWO, r14, 0 // repeat until signal high % is done
R1ZERO_TWO:
        MOV     r14, r13
        QBGE    NEWLOOP_TWO, r3,0
                              // set the output P9_28 low
        CLR     r30.t2
SIGNAL_LOW_TWO:
        MOV     r15, r2             // delay how long? load r2 above
DELAY_LOW_TWO:
        SUB     r15, r15, 1          // decrement loop counter
        QBNE    DELAY_LOW_TWO, r15, 0   // repeat until step delay is done
        SUB     r14, r14, 1          // the signal was low for a step
        QBNE    SIGNAL_LOW_TWO, r14, 0  // repeat until signal low % is done

        QBBS    END, r31.t5        // quit if button on P9_27 is pressed
        // Go to the next sample
NEWLOOP_TWO:
        SUB     r18,r18,1             // decrement the counter by 1
        QBLT    LESSTHAN100TWO,r18,0
                                    // otherwise loop forever
NEXTSAMPLE_TWO:
        ADD    r6,r6,1
        QBA    SAMPLELOOP

END:                               // end of program, send back interrupt
        MOV     R31.b0, PRU0_R31_VEC_VALID | EVENTOUT0
        HALT
