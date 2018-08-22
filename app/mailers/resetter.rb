class Resetter < ActionMailer::Base
   default from: 'admin@po-it.com'

  def reset(user)
    @token = user.token
    mail(to: user.email, subject: 'Password Reset Link')
  end
end