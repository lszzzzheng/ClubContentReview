# frozen_string_literal: true

# name: discourse-aliyun-moderation
# about: Pre-publish moderation via Aliyun multimodal gateway
# version: 0.1.0
# authors: ClubContentReview
# required_version: 3.2.0

enabled_site_setting :aliyun_moderation_enabled

after_initialize do
  module ::AliyunModeration
    PLUGIN_NAME = 'discourse-aliyun-moderation'

    class Error < StandardError; end
    class ReviewIntercept < StandardError; end
    class RejectIntercept < StandardError; end
  end

  require_relative 'lib/aliyun_moderation/gateway_client'
  require_relative 'lib/aliyun_moderation/payload_builder'
  require_relative 'lib/aliyun_moderation/review_queue'
  require_relative 'lib/aliyun_moderation/moderator'

  module ::AliyunModeration
    def self.enabled_for?(user)
      return false unless SiteSetting.aliyun_moderation_enabled
      return false if user&.staff?

      true
    end
  end

  DiscourseEvent.on(:before_create_post) do |creator|
    user = creator.user
    next unless ::AliyunModeration.enabled_for?(user)

    begin
      result = ::AliyunModeration::Moderator.moderate_before_create!(creator)

      if result[:decision] == 'REVIEW'
        ::AliyunModeration::ReviewQueue.enqueue!(creator: creator, result: result)
        raise ::AliyunModeration::ReviewIntercept
      elsif result[:decision] == 'REJECT'
        raise ::AliyunModeration::RejectIntercept
      end
    rescue ::AliyunModeration::ReviewIntercept
      creator.errors.add(:base, I18n.t('aliyun_moderation.review_required'))
      raise Discourse::InvalidAccess.new(I18n.t('aliyun_moderation.review_required'))
    rescue ::AliyunModeration::RejectIntercept
      creator.errors.add(:base, I18n.t('aliyun_moderation.rejected'))
      raise Discourse::InvalidAccess.new(I18n.t('aliyun_moderation.rejected'))
    rescue => e
      # Conservative fail-safe: send to review queue instead of direct publish.
      ::AliyunModeration::ReviewQueue.enqueue!(creator: creator, result: { decision: 'REVIEW', error: e.message, labels: [], risk_level: 'unknown' })
      creator.errors.add(:base, I18n.t('aliyun_moderation.review_required'))
      raise Discourse::InvalidAccess.new(I18n.t('aliyun_moderation.review_required'))
    end
  end
end
