char* toFind = "\"max_id\":\0";	// the character sequence we are looking for
byte state = 0;			
int pos=0;
int date_pos=0;
int tweetCount = 0;
char max_id[100];
int id_digits=0;
int i=0;
int charsRead=0;
byte done=0;
int openBracket=0;
byte beginning=0;

void parse(char c){
charsRead++;
  // Counting opening and closing brackets to determine how many tweets we got
  // Every tweet has two opening and closing brackets, 
  // so bracketcount devided by 2 gives us an approx tweetcount
  if(c == '{'){
    openBracket++;
    tweetCount++;
    beginning = 1;
  }
  else if(c == '}')
    openBracket--;
  if((openBracket == 0) && (beginning == 1)){
     done = 1; 
     tweetCount--;
     tweetCount = tweetCount/2;
     beginning = 0;
  }
 // We dont want Twitter to send us all the Tweets every time, 
 // parse the latest Tweet ID and send it next time, 
 // so we only get Tweet since the last Query.
  switch(state){
    case 0:{                   // find "id":
      if(c == toFind[pos]){
        pos++;
      }else{
        pos = 0;
      }
      if(pos == strlen(toFind)){
        state = 1;
        pos = 0;
      }
      break;
    }
    case 1:{                    // seperate id Numbers
     if(c == ',') {
       state = 2;
       max_id[i]='\0';
       i =0;
       break;
     }
     max_id[i]=c;
     i++;
     break; 
    }
    case 2:{                     // print that stuff to the console for debugging purposes
      Serial.println(max_id);
     Serial.println(tweetCount/2);
      state = 0; 
      break;
    }
  }
}

