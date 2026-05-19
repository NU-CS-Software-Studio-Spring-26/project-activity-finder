# Activity-finder

## Name
Mengpang Xing,
Grace He,
Yas’lyn Mohammed,
Jason Shao

## Objective
Find local events or activities (hikes, food crawls, etc.)
Parse social media posts and comments for suggestions
Post or join friends’ activities

## MVP
Cloud-based application where users can upload, browse, and join events in their city.



Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...



# Heroku Deployment
- https://activity-finder-8073ba70e16c.herokuapp.com/activities

### Google Sign-In on Heroku

Google OAuth fails on Heroku when the callback URL does not match what is registered in Google Cloud.

1. **Heroku Config Vars** (Settings → Config Vars):
   - `GOOGLE_CLIENT_ID` — same Web client as local dev (or a separate production client)
   - `GOOGLE_CLIENT_SECRET`
   - `APP_HOST` — your public app URL with **https**, no trailing slash, e.g. `https://activity-finder-8073ba70e16c.herokuapp.com`  
     Do **not** leave `APP_HOST` as `http://localhost:3000` on Heroku.  
     If `APP_HOST` is omitted, the app falls back to `https://<HEROKU_APP_NAME>.herokuapp.com` (Heroku sets `HEROKU_APP_NAME` automatically).

2. **Google Cloud Console** → Credentials → your OAuth 2.0 Web client → add for production:
   - **Authorized JavaScript origins:** `https://activity-finder-8073ba70e16c.herokuapp.com`
   - **Authorized redirect URIs:** `https://activity-finder-8073ba70e16c.herokuapp.com/auth/google_oauth2/callback`

3. **Redeploy** after changing config vars (`heroku restart` or push a new release).

4. If sign-in still fails, check logs: `heroku logs --tail` and look for `redirect_uri_mismatch` or OmniAuth warnings.


## Communication
For the remainder of the class, our team agrees to the following communication and decision-making rules:
- **Primary channel:** We use Slack/Imessage group chat for day-to-day communication.
- **Response time:** Each member responds within 24 hours on weekdays.
- **Meetings:** We meet at least once per week and post a short agenda beforehand.
- **Task tracking:** We track work using GitHub Issues and assign owners + due dates.
- **Decision-making:** We aim for consensus first; if blocked, majority vote decides.
- **Code review:** All pull requests require at least one teammate review before merge.
- **Respect & accountability:** We communicate respectfully, follow through on commitments, and notify the team early if timelines slip.


