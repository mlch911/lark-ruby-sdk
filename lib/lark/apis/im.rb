module Lark
  module Apis
    module Im
      # receive_id_type:
      #   可选值：open_id、user_id、union_id、email、chat_id
      #   默认值：open_id
      # payload 结构 --
      #   receive_id: 消息接收者
      #   content：消息内容
      #   msg_type：消息类型
      # API doc: https://open.feishu.cn/document/server-docs/im-v1/message/create
      # 内容文档: https://open.feishu.cn/document/server-docs/im-v1/message-content-description/create_json#45e0953e
      def send_message(payload, receive_id_type: :open_id)
        post 'im/v1/messages', payload, params: { receive_id_type: receive_id_type }.compact
      end

      # Sends a markdown message to a specified receiver.
      #
      # @param title [String] The title of the message.
      # @param markdown [String] The markdown content.
      # @param receive_id [String] The ID of the message receiver.
      # @param receive_id_type [Symbol] The type of receiver ID. Optional values: :open_id, :user_id, :union_id, :email, :chat_id. Default is :open_id.
      #
      # API doc: https://open.feishu.cn/document/server-docs/im-v1/message/create
      # 内容文档: https://open.feishu.cn/document/server-docs/im-v1/message-content-description/create_json#45e0953e
      #
      # @return [HTTP::Response] The response from the API call.
      def send_markdown_message(title: '', markdown:, receive_id:, receive_id_type: :open_id)
        content = {
          zh_cn: {
            title: title,
            content: [
              [
                {
                  tag: 'md',
                  text: markdown
                }
              ]
            ]
          }
        }
        send_message({
          receive_id: receive_id,
          content: content.to_json,
          msg_type: 'post'
        },
        receive_id_type: receive_id_type)
      end

      def upload_image(image, image_type)
        post_form 'im/v1/images', { image: HTTP::FormData::File.new(image), image_type: image_type }
      end

      def download_image(image_key, params = {})
        get "im/v1/images/#{image_key}", params: params, as: :file
      end

      # member_id_type:
      #   可选值：user_id、union_id、open_id、app_id
      #   默认值：open_id
      # succeed_type:
      #   0：兼容之前的策略，不存在/不可见的 ID 会拉群失败，并返回错误响应。存在已离职 ID 时，会将其他可用 ID 拉入群聊，返回拉群成功的响应。
      #   1：将参数中可用的 ID 全部拉入群聊，返回拉群成功的响应，并展示剩余不可用的 ID 及原因。
      #   2：参数中只要存在任一不可用的 ID ，就会拉群失败，返回错误响应，并展示出不可用的 ID。
      def add_members_to_chat(chat_id, id_list, member_id_type: :open_id, succeed_type: 1)
        post "im/v1/chats/#{chat_id}/members", { id_list: id_list }, params: {
          member_id_type: member_id_type,
          succeed_type: succeed_type
        }.compact
      end

      def remove_members_from_chat(chat_id, id_list, member_id_type: :open_id)
        delete "im/v1/chats/#{chat_id}/members", { id_list: id_list }, params: {
          member_id_type: member_id_type
        }.compact
      end

      def delete_chat(chat_id)
        delete "im/v1/chats/#{chat_id}"
      end
    end
  end
end
