# AD4134_TQ15EG

## Acknowledgements

This project re-uses HDL code provided by Analog Devices to configure AD4134 devices and move data into memory for transfer into a PC. Data capture is performed with HDL code provided by Adriaan Sadie.

**Links:**

https://github.com/analogdevicesinc/hdl

https://github.com/AdriaanSadie/AD4134

## AD4134
In the new design, padding is placed in the MSB of each word. The design provided by Analog Devices places padding at the LSB of each word. 

For 1's complement values:

Raw Values
|0                            2^N|
|---------------|----------------|
|-------------Range--------------|
|---------------|----------------|
|0         4.096 -0.001    -4.096|
|         Encoded Values         |
