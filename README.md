Softlayer Status Feed via iCal protocol
=======================================

Have you ever wanted to see the information about the upcoming Softlayer maintenance events in your calendar? This small application is created to help you with that. It pulld the data from the official Softlayer status page and provides you with an ICalendar (RFC-2445) compatible feed that could be added to Apple Calendar, Google Calendar or other compatible clients.

How to use it?
==============

If you want to get information about all Softlayer's scheduled maintenances, just add the following calendar feed URL to your Calendar application:

    webcal://sl-status.herokuapp.com/softlayer.ics

If you only want to see information about specific datacenters, use the following URL format:

    webcal://sl-status.herokuapp.com/softlayer.ics?dc=DATACENTERS

where DATACENTERS is a comma-delimited list of datacenter names (e.g. DAL01, DAL05, SNG01, etc).
