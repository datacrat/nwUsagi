# nwUsagi
nwUsagi is a simple script set to import network usage data into Tableau.
<img width="1792" alt="ScreenShot 2020-04-09 22 37 04" src="https://user-images.githubusercontent.com/62040535/78901268-0af84980-7ab3-11ea-9304-fd825afe67ae.png">
Fig.1: An example of network usage graph using nwUsagi

# Description
MRTG and its variants such as Cacti are popular to graph the network utilization.
However, those tools produce graphs in picture format and you cannot drill down the data by poking around the picture.

Today, we have many good visualization solutions.
Tableau is one of the most sprendid tools, which has many beautiful easy-to-use graph templates and has dashboard to present data in effective ways.
It is a commercial product, but Tableau provides [Tableau Public](https://public.tableau.com/) for free.

nwUsage provides the way to produce network usage graphs in Tableau.
It polls the usage data from network devices in the same way as MRTG and present the data in Tableau in much more beautiful and flexible forms.

# Mechanism
nwUsagi is a software runs in a server (such as Linux).
It polls usage data from network devices using SNMP, stores the history data and provides the data to Tableau via Web Data Connector.

![diagram](https://user-images.githubusercontent.com/62040535/78906806-cb356000-7aba-11ea-9f7a-d4d45fb9ef3b.png)
Fig.2: nwUsagi diagram

# Prerequisites
- Any UNIX variants with
  - bash
  - net-snmp
  - apache 2.4+
  - jq
(Tested in CentOS7)
- The monitored network device should be able to be polled using SNMP

# Installation
1. Download nwusagi-master.zip

2. Extract the zip file and you will find "nwusagi-master" directory

3. Rename that directory to "nwusagi" and move it under /var/lib, so that you will have
~~~
    /var/lib/nwusagi/
                     api/
                     bin/
                     conf/
                     data/
                          live/
                     html/
                     tmp/
~~~ 

4. `chown -R apache:apache /var/lib/nwusagi`

5. Determine the UNIX user id to run poll script. The user must be able to write into /var/lib/nwusagi/data/live and /var/lib/nwusagi/tmp directory.
The most straightforward way is 1) to make the user belongs to the same group as apache user
and 2) `chmod -R g+w /var/lib/nwusagi`

6. Edit `conf/devices` file.
If you would like to monitor a device whose name is 'rtr',
whose IP address is '192.168.1.254'
and whose SNMP (read) community is 'mypublic",
`echo -e "rtr\t192.168.1.254\tmypublic" >> /var/lib/nwusagi/conf/devices` will do.

7. Configure crontab for cron to kick the poll script every X minutes.
If you configure every 5 minutes poll against the device 'rtr',
`0-59/5 * * * *	/var/lib/nwusagi/bin/nwuUpdate.sh rtr` is the entry to add.

8. Add `IncludeOptional /var/lib/nwusagi/conf/httpd-*.conf` into httpd.conf, so that httpd reads /var/lib/nwusagi/conf/httpd-nwusagi.conf.

9. Restart Apache httpd.


# How to pull data into Tableau

1. Run Tableau Desktop (or Tableau Public)

2. In "Connect" pane, select "Web Data Connector" in "To a Server" section.

3. Put "http(s)://<Your server's addr/FQDN>/nwusagi/wdc.html?device=&lt;device name&gt;".

4. You will see the list of columns. The 1st column is always Timestamp. The rest are [IN] and [OUT] of all the interfaces of the device.

5. Push "Pull Data" button below the list.

6. You will find the table "nwUsagi WDC (<device name>)".

7. Press "Sheet 1" bottom of the window.

8. From "Dimensions", drag "Timestamp" and drop it to "Columns". Hover over the dragged item (should be "YEAR(Timesta..)",
press triangle and select "More" -> "Minute".

<img width="353" alt="ScreenShot 2020-04-10 0 28 57" src="https://user-images.githubusercontent.com/62040535/78912399-8281a500-7ac2-11ea-967e-29f3ecb0c4ea.png">
Fig.3: Menu to select

9. From "Measures" pick one of the metrics and drag&drop it to "Rows".

10. You will see a continuous line graph is drawn.

I'm not a Tableau expert, but above will gives you an idea how to use the imported data further.

# Limitations and Restrictions
- Currently, nwUsagi polls ifInOctets and ifOutOctets, whose data type is Counter32 (unsigned 32-bit integer).
So for high speed network interfaces with long poll frequency will result in incorrect usage.
(ToDo: Pull ifHCInOctets/ifHCOutOctets instead of IfInOctets/IfOutOctets. Use python instead of awk to calculate Counter64 data correctly.)

# License
[MIT License](https://github.com/datacrat/nwusagi/blob/master/LICENSE)

# Author
[datacrat](https://github.com/datacrat/)

