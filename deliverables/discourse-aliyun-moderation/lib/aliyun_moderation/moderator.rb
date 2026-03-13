# frozen_string_literal: true

module ::AliyunModeration
  class Moderator
    def self.moderate_before_create!(creator)
      payload = ::AliyunModeration::PayloadBuilder.from_creator(creator)

      client = ::AliyunModeration::GatewayClient.new(
        url: SiteSetting.aliyun_moderation_gateway_url,
        timeout_ms: SiteSetting.aliyun_moderation_timeout_ms
      )

      result = client.moderate!(payload)
      normalize_result(result)
    rescue => e
      if SiteSetting.aliyun_moderation_fail_safe_mode == 'pass'
        return { decision: 'PASS', risk_level: 'unknown', labels: [], error: e.message }
      end
      raise e
    end

    def self.normalize_result(result)
      decision = result['decision'].to_s.upcase
      decision = 'REVIEW' unless %w[PASS REVIEW REJECT].include?(decision)

      {
        decision: decision,
        risk_level: result['risk_level'].to_s,
        labels: Array(result['labels']),
        req_id: result['req_id'].to_s,
        error: result['error'].to_s
      }
    end
  end
end
