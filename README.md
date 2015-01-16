# LTI Javascript app wrapper

This server application turns any Javascript app into an [IMS LTI 1.1](http://www.imsglobal.org/LTI/v1p1/ltiIMGv1p1.html) tool provider. [Edu Apps](https://www.edu-apps.org) has a good [description of how LTI works](https://www.edu-apps.org/code.html).

The benefits of servering your Javascript app as an LTI Tool instead of a simple page are:
- Your Javascript app will know the identity of the learner, passed from the LTI Tool Consumer
- Your app can send a result back to the LTI Tool Consumer at the end with the learner's percentage grade
- You can launch it from an LTI Tool Consumer such as [Coursera](https://tech.coursera.org/app-platform/lti/)

This web app provides some additional benefits:
- Your configure your web page content using forms instead of file uploads
- Your Javascript app is provided functions to log in a common format
- You can download the log data from this web application

## Getting started

If you want to use this app as is, you can simply click below to spin up a web server using your free Heroku account.

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

To get deeper in, you may want to fork this repo and start poking around. It's a simple [Ruby on Rails](http://guides.rubyonrails.org/index.html) application.
