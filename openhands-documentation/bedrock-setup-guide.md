# Comprehensive Guide: Configuring OpenHands with AWS Bedrock

This guide provides a detailed, step-by-step walkthrough for configuring OpenHands to use a secure AWS Bedrock endpoint. This is intended for a technical audience and assumes familiarity with the AWS Management Console and IAM.

## Introduction

Using AWS Bedrock as the backend LLM for OpenHands provides significant advantages in an enterprise setting:
- **Security:** Your data and code do not leave your AWS environment.
- **Compliance:** Leverages AWS's compliance certifications.
- **Model Choice:** Access to a variety of foundation models from Amazon and third-party providers.
- **Scalability:** Managed and scalable inference endpoints.

We will configure this integration by:
1.  **Creating a dedicated IAM User** with the principle of least privilege.
2.  **Enabling Model Access** in Bedrock for the desired foundation model.
3.  **Generating AWS Credentials** for the IAM user.
4.  **Constructing the `podman run` command** with the correct credentials and parameters.

---

## Step 1: Enable Model Access in AWS Bedrock

Before you can use a model, you must enable access to it within the Bedrock service.

1.  Navigate to the **Amazon Bedrock** service in the AWS Management Console.
2.  Ensure you are in the correct region (**us-east-1**).
3.  In the bottom-left navigation pane, click on **Model access**.
4.  Review the available models. If the model you intend to use (e.g., `anthropic.claude-v2`, `amazon.titan-text-express-v1`) is not already listed with "Access granted", click the **Manage model access** button in the top-right.
5.  Check the box next to the desired model(s) and click **Request model access**. Access is typically granted instantly.

**Note:** For this guide, we will use `anthropic.claude-v2` as an example. You must replace this with the `modelId` you have enabled and intend to use.

---

## Step 2: Create a Dedicated IAM Policy and User

For security, we will create a new IAM user with a policy that *only* grants permission to invoke the specific Bedrock model. **Do not use your personal or an administrator account's credentials.**

### 2.1. Create the IAM Policy

1.  Navigate to the **IAM** service in the AWS Management Console.
2.  Go to **Policies** and click **Create policy**.
3.  Switch to the **JSON** tab and paste the following policy document:

    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowBedrockInvokeModel",
                "Effect": "Allow",
                "Action": "bedrock:InvokeModel",
                "Resource": "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-v2"
            }
        ]
    }
    ```

4.  **Crucially, modify the `Resource` ARN**: Replace `anthropic.claude-v2` with the exact `modelId` you enabled in Step 1.
5.  Click **Next: Tags**, then **Next: Review**.
6.  Give the policy a descriptive name, such as `OpenHands-Bedrock-Invoke-Policy`, and a description.
7.  Click **Create policy**.

### 2.2. Create the IAM User

1.  In the IAM service, go to **Users** and click **Add users**.
2.  Enter a **User name**, for example, `openhands-service-user`.
3.  Select **Access key - Programmatic access** as the AWS credential type.
4.  Click **Next: Permissions**.
5.  Select **Attach existing policies directly**.
6.  Search for and select the `OpenHands-Bedrock-Invoke-Policy` you just created.
7.  Click **Next: Tags**, then **Next: Review**, then **Create user**.

### 2.3. Securely Store Credentials

1.  On the final screen, you will see the **Access key ID** and **Secret access key**.
2.  **This is the only time the secret access key will be shown.** Copy both values immediately and store them in a secure location (like a password manager).
3.  You will use these credentials in the next step.

---

## Step 3: Construct and Run the Podman Command

Now we will assemble the final `podman run` command using the credentials you just created.

Execute this command on the isolated machine's terminal.

```bash
podman run -it --rm --pull=always \
 -e SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.48-nikolaik \
 -e LOG_ALL_EVENTS=true \
 -e LLM_API_KEY="YOUR_SECRET_ACCESS_KEY" \
 -e LLM_BASE_URL="https://bedrock-runtime.us-east-1.amazonaws.com" \
 -e AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID" \
 -e AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY" \
 -e AWS_REGION="us-east-1" \
 -e LLM_MODEL="anthropic.claude-v2" \
 -v /run/podman/podman.sock:/var/run/docker.sock \
 -v ~/.openhands:/.openhands \
 -p 3000:3000 \
 --name openhands-app \
 docker.all-hands.dev/all-hands-ai/openhands:0.48
```

**Parameter Breakdown:**

-   `LLM_API_KEY`: While somewhat redundant because we are providing specific AWS keys, it's best practice to populate it. Use your AWS Secret Access Key here.
-   `LLM_BASE_URL`: The regional endpoint for the Bedrock runtime.
-   `AWS_ACCESS_KEY_ID`: The Access Key ID for the `openhands-service-user`.
-   `AWS_SECRET_ACCESS_KEY`: The Secret Access Key for the `openhands-service-user`.
-   `AWS_REGION`: The AWS region where your Bedrock model is hosted.
-   `LLM_MODEL`: The `modelId` of the foundation model you have enabled and are authorized to use.

---

## Step 4: Verification and Troubleshooting

1.  After running the command, Podman will pull the image and start the container.
2.  Access the UI at `http://<IP_OF_ISOLATED_MACHINE>:3000`.
3.  Attempt to give the agent a simple task, like "write a hello world python script".
4.  **Check the Logs:** If you encounter errors, the container logs are the first place to look. Run `podman logs openhands-app` in a separate terminal on the isolated machine.

**Common Errors and Solutions:**

-   **`AccessDeniedException` in logs:** This almost always means there is an IAM permission issue.
    -   Double-check that the IAM policy ARN matches the `LLM_MODEL` in your `podman run` command *exactly*.
    -   Verify that the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct and do not have any typos or extra whitespace.
-   **`ValidationException` or `ModelNotFoundException`:**
    -   Ensure the `LLM_MODEL` ID is correct.
    -   Verify you have enabled access to this model in the Bedrock console (Step 1).
-   **Connection Timeouts:**
    -   Confirm the isolated machine has network connectivity to the Bedrock endpoint. You can test this with `curl -v https://bedrock-runtime.us-east-1.amazonaws.com`.
-   **Podman Socket Errors:**
    -   Ensure the path `-v /run/podman/podman.sock:/var/run/docker.sock` is correct for your Podman installation.

This detailed guide should provide the clarity and depth needed to successfully deploy OpenHands with AWS Bedrock in your environment.
