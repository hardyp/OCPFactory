# OCPFactory
Open-Closed Principle Factory

FUNCTIONALITY

Follow this link for a description of the "Open-Closed Principle"
https://en.wikipedia.org/wiki/Open-closed_principle
In essence the idea is somewhat like Black Magic - you can change the behaviour of a program without actually changing the program itself.
That sounds impossible - ridiculous even - but in fact there are many ways to do this. The mechanism you will be most familiar with would be user exits inside standard SAP programs, and the IMG to alter standard program behaviour via customising.
If it's good enough for SAP it is good enough for me; so this factory class is designed in a way such that you pass in what you expect the concrete class you desire to be capable of and the most appropriate class that implements the interface is passed back.

EXAMPLE

That sounds a bit obscure so let us have a real life example. You have a main class - be it a model class, view class, whatever - that needs to behave slightly differently for different countries and/or business lines and you have new countries and/or business lines coming on stream like there is no tomorrow.
What you do is pepper that class with "exit" methods which can then be redefined in country and/or business line specific subclasses.
Then when - say - Hong Kong comes online you can just add a new Hong Kong specific subclass and the main program will automatically pick that subclass when a Hong Kong users tries to run the transaction -without having to change the main program at all.
Moreover using this mechanism the new Hong Kong specific logic cannot possibly break the logic for any other country on the grounds it is never called for those countries.

PROCEDURE

The class you desire to create has to implement the ZIF_CREATED_VIA_OCP_FACTORY interface. The "context" data e.g. country, business line or anything at all, is passed into method IS_THE_RIGHT_CLASS_TYPE_GIVEN and the subclass which is the best match for the requirements is passed back.

DEPENDENCIES

This package has a dependency on the package at the GitHub URL https://github.com/hardyp/DesignByContract
Hopefully as this package has a marker interface APACK will sort this out for you automatically.

FURTHER_SOURCES_OF_INFO

Please read this blog:-
https://blogs.sap.com/2017/04/17/charlie-and-the-chocolate-factory-pattern/
