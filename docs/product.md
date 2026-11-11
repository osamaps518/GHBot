# Product and modules

What GHbot does, who uses it, how it splits into modules, and what each module must do.

## Users

GHbot is for adults who train, mainly aged 18 to 50. Nobody under 18 can sign up.

| User | Who they are |
|---|---|
| **Trainee** | Uses the app for their own training and nutrition. |
| **Health professional** | A trainee's doctor or dietitian. Can set that trainee's targets. |
| **Trainer** | A human trainer at a gym. Sees the logs of trainees who allowed it. |
| **Gym owner** | Runs a partner gym. Sees the sign-ups and earnings from its code. |
| **Admin** | Manages foods, exercises, partner gyms and the research library. |


Expert advisors (a dietitian, an exercise scientist) approve the research library and the regional dishes. Whether they do that inside the app or outside it is open.

## Outside systems


| System | Used for |
|---|---|
| **Authentication provider** | Sign-up, sign-in and passwords (decision 5). |
| **Model provider** | The coach's answers, and searching the research library (decision 7). |
| **Food data sources** | USDA FoodData Central and Open Food Facts, also for barcodes. Licenses still to check. |
| **Research sources** | PubMed and PubMed Central, for the research library. |
| **App store billing** | Google Play subscriptions. |
| **Payout provider** | Paying gyms their commission. May be limited by where we are. |
| **Push notification service** | Reminders on the phone. |
| **Email sender** | Account emails. May come with the authentication provider. |
| **Analytics tool** | Possibly, for the Analytics module. We may not need one. |
| **Hosting and database provider** | Where the backend runs (decision 6). |

## Modules

| Module | What it is | Needs |
|---|---|---|
| **Accounts** | Who you are and getting in. | The authentication provider |
| **Profiles** | What a trainee tells us about themselves, and their preferences. | Accounts |
| **Targets** | Daily calories and macros. | Profiles |
| **Food database** | The foods a trainee can log. | The food data sources |
| **Food log** | What a trainee ate. | Food database, Targets |
| **Exercise library** | The exercises a trainee can log. | Nothing |
| **Workout log** | What a trainee trained. | Exercise library |
| **Progress** | How it's going over time. | Food log, Workout log, Targets |
| **Coach** | The AI chat. | Research library, Profiles, Targets, the logs, the model provider |
| **Research library** | The sources the coach may answer from. | The research sources |
| **Supervision** | Other people linked to a trainee's account. | Accounts, Targets, the logs |
| **Gyms and referrals** | Partner gyms and their codes (#29). | Accounts, Subscriptions, the payout provider |
| **Subscriptions** | Free and premium. | Accounts, app store billing |
| **Notifications** | What the app tells a trainee without being asked. | The push notification service |
| **Analytics** | Numbers about the whole app, for admins. | Every other module, possibly an analytics tool |

## Requirements

### Accounts

- A person can sign up.
- A person can sign in.
- A person can sign out.
- A person can reset a forgotten password.
- A person can delete their account and their data. 
- A person under 18 can't sign up.
- A person sees the terms, the privacy policy and a "not medical advice" notice before using the app.
- Health professionals, trainers and gym owners each have their own kind of account. 

### Profiles

- A trainee can enter their birth month and year, sex, height, weight, activity level and goal.
- A trainee can change this information at any time.
- A trainee can enter their training experience (#27).
- A trainee can enter the equipment they have (#27).
- A trainee can choose the app's language: Arabic or English (#28). Hebrew comes later (#25).
- A trainee can choose metric or imperial units (#26).

### Targets

- A trainee sees their daily calorie target.
- A trainee sees their daily protein, carbs and fat in grams.
- A trainee can see how the targets were calculated.
- A target is never below the safe minimum, and the trainee is told when the minimum was used.
- A trainee over 78 sees a warning before their targets.
- A trainee can set their own targets (#21).
- A trainee can go back to the recommended targets (#21).
- A trainee can see the history of their target changes (#21).
- The app suggests a new target when the trainee's weight trend doesn't match their goal, and the trainee accepts or declines (#24).
- A trainee sees when their targets were set by their health professional (#23).

### Food database

- A trainee can search for a food in Arabic or English.
- A trainee can find regional dishes, such as maqluba and musakhan.
- A trainee can pick a food's amount in everyday units (a piece, a cup) or in grams.
- A trainee can add their own food.
- A trainee can find a packaged food by scanning its barcode.
- An admin can add a food.
- An admin can fix a food's values.
- A dietitian approves the regional dishes (#34).

### Food log

- A trainee can log a food they ate.
- A trainee can change a logged entry.
- A trainee can delete a logged entry.
- A trainee can see the day's totals next to their targets.
- A trainee can see past days.
- A trainee can move an entry to another day.
- A trainee can log without internet, and the entries are saved once back online.
- A trainee's day starts at 4 a.m., so a late-night meal counts toward the day before.
- A trainee can change when their day starts.
- The app suggests a later day start to a trainee who often eats late (#36).
- A trainee sees a "Corrected" label on past entries of a food whose values were fixed.
- A trainee can log a meal from a photo.

### Exercise library

- A trainee can browse the exercises.
- A trainee can search for an exercise in Arabic or English.
- A trainee can filter exercises by equipment.
- An admin can add an exercise.
- An admin can fix an exercise.

### Workout log

- A trainee can log a workout: its exercises, and the sets, reps, weight and effort (RPE) of each.
- A trainee can change a logged workout.
- A trainee can delete a logged workout.
- A trainee can see their past workouts.
- A trainee can see their personal records.
- A trainee can see their estimated one-rep max for an exercise.
- A trainee can log without internet, and the workouts are saved once back online.

### Progress

- A trainee can log their weight.
- A trainee can see their weight trend.
- A trainee can see their strength trend.
- A trainee can see how often they logged and met their targets.
- A trainee earns streaks and badges, and never loses one they earned.
- A trainee gets a weekly report.

### Coach

- A trainee can ask the coach a question about training or nutrition.
- Every answer shows the sources it came from.
- The coach says so when the research doesn't cover a question.
- The coach declines questions outside training and nutrition.
- The coach answers a medical red flag (injury pain, diabetes, pregnancy, medication) with a safe reply and a referral to a professional.
- The coach answers signs of an eating disorder with support and a referral, not numbers.
- The coach's answers take the trainee's profile, targets, logs, experience and equipment into account.
- The coach explains the app's numbers but never calculates its own.
- The coach never recommends eating below the safe minimum.
- The coach never uses BMI to describe a trainee.
- The coach gives no calorie advice to a trainee whose targets were set by a health professional.
- A trainee can read their past conversations. *(proposed)*
- A trainee can get a training program built from the research.
- An admin can run a set of test questions to check the coach's answers and sources.

### Research library

- An admin can add a source with its details (title, year, study type, evidence grade).
- An admin can remove a source.
- The coach uses a source only after an expert advisor approved it.
- The library keeps only abstracts, open-access papers and our own summaries.

### Supervision

- A trainee can add their health professional.
- A trainee can remove their health professional.
- The app suggests adding a health professional to a trainee with a BMI of 30 or more, or over 78.
- A health professional can set the targets of a trainee linked to them.
- A target below the safe minimum is only possible when set under a health professional, and never below 800 kcal.
- A trainee can allow a trainer to see their logs.
- A trainee can take that permission back.
- A trainer can see the logs of trainees who allowed it.
- Nobody sees a trainee's data without the trainee's permission.

### Gyms and referrals

- An admin can add a partner gym.
- Each partner gym gets its own code and a QR poster.
- A trainee can enter a gym's code when signing up.
- A trainee who signed up with a code gets a longer free trial (not final).
- A gym owner can see how many trainees signed up with the gym's code.
- A gym owner can see how many of them are subscribed.
- A gym owner can see the gym's earnings.
- A gym earns a share of each referred trainee's payments for 12 months.
- A gym is paid monthly, once its earnings pass a minimum.
- A gym never sees a trainee's health data.
- A trainee gets a free premium month for each friend who joins.

### Subscriptions

- A trainee can use food and workout logging for free.
- A free trainee can send a limited number of coach messages.
- A trainee can start a free trial of premium.
- A trainee can subscribe to premium.
- A trainee can cancel their subscription.
- A premium trainee gets unlimited coach messages, training programs and weekly reports.

### Notifications

- A trainee gets a reminder to log. *(proposed)*
- A trainee is notified when their weekly report is ready.
- A trainee can turn each kind of notification off. *(proposed)*

### Analytics

- An admin can see how many trainees there are and how many signed up recently.
- An admin can see how many trainees log a meal and a workout in their first week.
- An admin can see how many trainees are still active after 7, 30 and 90 days.
- An admin can see how many free trainees became premium.
- An admin can see how often the coach cites correctly and declines correctly.
- An admin can see the sign-ups per gym and how many partner gyms are active.
- These numbers never show one trainee's health data.

## Archived

Ideas we keep but don't plan for. They come back only if the app grows enough to need them.

- **Teen mode** (#22): trainees aged 13–17 with a parent's approval. Dropped for now because of the consent and legal work. It would add two users, the teen trainee and the parent.
- **Ramadan mode** (#35): the day starts at dawn during Ramadan. It would add an outside system, a prayer times source.
