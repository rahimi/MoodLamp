#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <EthernetDNS.h>

// Every Ethernetport has a unique mac adress. Randomly picked semi unique ;-)
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte first = 1; 		// first run?
long lastChecked = 0;	// time when we last checked
int totalSec=0;		// total seconds since last checked
int totalTweetsInMin=0;	// tatol amount of tweets in 60 seconds
extern char max_id[];	// the last tweet id (higher value means newer tweet)
extern int tweetCount;	// tweet count from last query
extern byte done;	// parsing is finished?
const char* ip_to_str(const uint8_t*);

void setup()
{
  // 1. We chose 115200 baudrate but you can go slower if you want. Remeber to change this in the Console too.
  Serial.begin(115200);
  // 2. Every Ethernetport has a unique mac adress. 
  EthernetDHCP.begin(mac, 1);
}

void loop()
{
  static DhcpState prevState = DhcpStateNone;
  static unsigned long prevTime = 0;

// Poll DHCP and switch through the states. Interesting for us though is only 
  DhcpState state = EthernetDHCP.poll();
  if (prevState != state) {
    switch (state) {
  // case …. You should probably check for other states here too, like: DhcpStateDiscovering, DhcpStateRequesting,
 //  DhcpStateRenewing
      case DhcpStateLeased: {
        const byte* dnsAddr = EthernetDHCP.dnsIpAddress();
        EthernetDNS.setDNSServer(dnsAddr);
        break;
      }
     }
     // We have to wait until we get the adress, timeout is 300 ms
   } else if (state != DhcpStateLeased && millis() - prevTime > 300) { 
    prevTime = millis();
    Serial.print('.'); 
// OMG: I can haz internetz!  
}  else if (state == DhcpStateLeased) {
    byte ipAddr[4];
    // Query the ip adress of the URL we want to connect to
    DNSError err = EthernetDNS.sendDNSQuery("search.twitter.com"); 
    if (DNSSuccess == err) {
      do {
        err = EthernetDNS.pollDNSReply(ipAddr);
        if (DNSTryLater == err) {
          delay(20);
          Serial.print(".");
        }
      } 
      while (DNSTryLater == err);
    }
    if (DNSSuccess == err) {
      // Woohoo! Now we can connect to the Server, finally :-)
      Client client(ipAddr, 80);
      while (client.connect()) {
        Serial.println("connected"); 
        //  refresh lights state           
         signalLamp( 0 ); 
        // Make a HTTP request: 1. GET Request with search term. 2. Since_id 3.User agent and Host 
        client.print("GET /search.json?q=twitter");
       // For every subsequent query we set the since_id of the query to the max id from the last one, so 
       // we only get the Tweets that are new since we last looked. Smart isn’t it!
       if(first==1) { 
          first = 0;
          lastChecked = millis();
        } else {
          client.print("&since_id=");
          client.print(max_id);
        }
        // Finally append the User Agent, Host and conclude that with a last carriage return. 
        // Otherwise Twitter won’t answer our biddings.
        client.println(" HTTP/1.0\r\nUser-Agent:Arduino\r\nHost:search.twitter.com\r\n\r\n");
        client.println();
        // Wait for the answer and parse that stuff! Character by character...
        while(done==0) {
          if (client.available()) {
            char c = client.read();
            parse(c);
          }
        }
        Serial.println("Done!!");
        // Count the Tweets until we reach a minute of asking Twitter for new Tweets. 
        totalSec = (millis()-lastChecked)/1000;
        totalTweetsInMin+=tweetCount;
        if(totalSec >= 60){
          Serial.print("New Tweets per Minute: ");
          Serial.println(totalTweetsInMin);     
          //  refresh lights state 
          signalLamp( totalTweetsInMin );  
          // refresh variables
          totalSec = 0;
          totalTweetsInMin = 0;
          lastChecked = millis();
        } else {           
           signalLamp( 0 );  
        }
        tweetCount = 0;
        done = 0;
        client.stop();
      } 
    } 
    else if (DNSTimedOut == err) {
      Serial.println("Timed out.");
    } 
    else if (DNSNotFound == err) {
      Serial.println("Does not exist.");
    } 
    else {
      Serial.print("Failed with error code ");
      Serial.print((int)err, DEC);
      Serial.println(".");
    } 
  }
  prevState = state;               // This is a statemashine, so set the new state properly
}

