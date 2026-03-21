web: bundle exec rails server -p ${PORT:-3000} -e ${RAILS_ENV:-production}
worker: bundle exec sidekiq -c ${SIDEKIQ_CONCURRENCY:-5}
