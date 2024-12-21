/* eslint-disable react-hooks/rules-of-hooks */
import { Meta, StoryObj } from "@storybook/react";
import styled from "styled-components";

const Patterned: React.FC<{ propsList: ComponentProps[] }> = ({ propsList }) => {
  return (
    <>
      {propsList.map((props) => {
        return <Component {...props} key={props.key} />;
      })}
    </>
  );
};

export default {
  title: "",
  component: Patterned,
} as Meta<typeof Patterned>;

type Story = StoryObj<typeof Patterned>;

export const _Patterns: Story = {
  name: "Patterns",
  args: {
    propsList: [],
  },
};
